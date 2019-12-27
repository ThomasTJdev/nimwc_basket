#
#
#        TTJ
#        (c) Copyright 2019 Thomas Toftgaard Jarløv
#        Plugin for Nim Website Creator: Buy
#        License: MIT
#
#

import
  asyncdispatch,
  datetime2human,
  logging,
  mime,
  os,
  otp,
  parsecfg,
  smtp,
  strutils

from times import epochTime

import ../../nimwcpkg/constants/constants
import ../../nimwcpkg/emails/emails
import ../../nimwcpkg/files/files
import ../../nimwcpkg/passwords/passwords
import ../../nimwcpkg/plugins/plugins
import ../../nimwcpkg/webs/captchas

import pdfreceipt
export pdfBuyGenerator

when defined(postgres): import db_postgres
else:                   import db_sqlite

proc pluginInfo() =
  let (n, v, d, u) = pluginGetDetails("basket")
  echo " "
  echo "--------------------------------------------"
  echo "  Package:      " & n
  echo "  Version:      " & v
  echo "  Description:  " & d
  echo "  URL:          " & u
  echo "--------------------------------------------"
  echo " "
pluginInfo()


let
  appDir = getAppDir().replace("nimwcpkg", "")
  dict = loadConfig(appDir / "config/config.cfg")
  supportEmail = dict.getSectionValue("SMTP", "SMTPEmailSupport")
  smtpAddress = dict.getSectionValue("SMTP", "SMTPAddress")
  smtpPort = dict.getSectionValue("SMTP", "SMTPPort")
  smtpFrom = dict.getSectionValue("SMTP", "SMTPFrom")
  smtpUser = dict.getSectionValue("SMTP", "SMTPUser")
  smtpPassword = dict.getSectionValue("SMTP", "SMTPPassword")

# Translation
const
  transReceipt* = "Faktura"
  transPrice = "Pris"
  transPricePer = "Pris/styk"
  transVat = "Moms"
  transVatS = "moms"
  transIncl = "Inkl."
  transInclVat = "inkl. moms"
  transBuy = "Køb"
  transNext = "Videre"
  transBack = "Tilbage"
  transAcceptConditions = """Ved at trykke "Køb bog" bekræfter du en købsaftale og <a href="/basket/conditions" target="_blank">handelsbetingelserne</a>. Der vil blive genereret en faktura."""
  transCongratulations = """
    <h1>Tillykke!</h1>
    <p>Du skal nu blot betale for varen, og så er den på vej til dig.</p>
    <p>Vi har sendt dig en email med fakturaen. Du kan også downloade din faktura nedenfor.</p>"""


# Mail
const
  mailSubjectCongrats* = """
    $1: Faktura for $2
  """
  mailMsgCongrats* = """
    <p>Hej $1</p>
    <p>Mange tak for dit køb.</p>
    <p>Du skal blot betale fakturaen, og herefter vil dit køb blive afsendt.</p>
    <hr>
    <p><b>Vare:</b> $2</p>
    <p><b>Pris:</b> $3</p>
    <p><b>Faktura nr.:</b> $8</p>
    <p>
      <b>Betaling:</b>
      <br>
      $4
    </p>
    <hr>
    <p>Du kan finde alle dine fakturaer på: <a href="$5">Login til fakturaer</a></p>
    <p>Hvis du har spørgsmål til din faktura eller forsendelsen, kan du altid kontakte os på <a href="mailto:$6">$6</a></p>
    <p>Mvh<br>$7</p>
  """
  mailSubjectShipped* = """
    $1: Din ordre er afsendt
  """
  mailMsgShipped* = """
    <p>Hej $1</p>
    <p>Din ordre er nu afsendt. Vi håber, at du bliver glad for din vare.</p>
    <hr>
    <p>Du kan finde alle dine fakturaer på: <a href="$2">Login til fakturaer</a></p>
    <p>Hvis du har spørgsmål til din faktura eller forsendelsen, kan du altid kontakte os på <a href="mailto:$3">$3</a></p>
    <p>Mvh<br>$4</p>
  """


include "nimfs/settings.nimf"
include "nimfs/accounting.nimf"
include "nimfs/basket.nimf"
include "nimfs/products.nimf"
include "nimfs/shipping.nimf"



proc sendBasketReceipt*(mailTo, subject, msg, filepath, receiptNr: string) {.async.} =
  ## Send email with the receipt as an attachment
  var multi = newMimeMessage()

  # Main data
  multi.body = msg
  multi.header["to"] = @[mailTo].mimeList
  multi.header["subject"] = subject

  # Add test to email body
  var first = newMimeMessage()
  first.header["Content-Type"] = "text/html"
  first.body = msg
  # Check if encoding is needed
  first.encodeQuotedPrintables()
  multi.parts.add first

  # Add attachement
  var image = newAttachment(readFile(filepath), filename = transReceipt & "_" & receiptNr & ".pdf")
  image.encodeQuotedPrintables()
  multi.parts.add image

  ## Send it using smtp
  var smtpConn = newAsyncSmtp(useSsl = true, debug = false)

  try:
    await smtpConn.connect(smtpAddress, Port(parseInt(smtpPort)))
    await smtpConn.auth(smtpUser, smtpPassword)
    await smtpConn.sendMail(smtpFrom,  @[mailTo], $multi.finalize())
    await smtpConn.close()
  except:
    error("Plugin Basket: Error in sending receipt")

proc basketStart*(db: DbConn) =
  ## Required proc. Will run on each program start
  ##
  ## If there's no need for this proc, just
  ## discard it. The proc may not be removed.

  info("Buy plugin: Updating database with Buy table if not exists")

  if not db.tryExec(sql"""
  create table if not exists basket_settings (
    id INTEGER primary key,
    receipt_nr_next     INTEGER,
    companyName         TEXT,
    companyDescription  TEXT NOT NULL,
    paymentMethod       TEXT NOT NULL,
    conditions          TEXT,
    countries           VARCHAR(1000),
    mailOrder           VARCHAR(10),
    mailShipped         VARCHAR(10),
    modified timestamp not null default (STRFTIME('%s', 'now')),
    creation timestamp not null default (STRFTIME('%s', 'now'))
  );""", []):
    error("Buy plugin: Could not create table")


  if not db.tryExec(sql"""
  create table if not exists basket_products (
    id INTEGER          primary key,
    identifier          VARCHAR(200),
    productName         TEXT NOT NULL,
    productDescription  TEXT,
    price               INTEGER,
    vat                 INTEGER,
    valuta              VARCHAR(10),
    picture             TEXT,
    modified timestamp not null default (STRFTIME('%s', 'now')),
    creation timestamp not null default (STRFTIME('%s', 'now'))
  );""", []):
    error("Buy plugin: Could not create table")


  if not db.tryExec(sql"""
  create table if not exists basket_shipping (
    id INTEGER   primary key,
    name         TEXT NOT NULL,
    description  TEXT,
    price        INTEGER,
    vat          INTEGER,
    valuta       VARCHAR(10),
    modified timestamp not null default (STRFTIME('%s', 'now')),
    creation timestamp not null default (STRFTIME('%s', 'now'))
  );""", []):
    error("Buy plugin: Could not create table")



  #[
    payment_received
      payed
      awaiting
      notchecked
      canceled
  ]#
  if not db.tryExec(sql"""
  create table if not exists basket_purchase (
    id INTEGER primary key,
    product_id  INTEGER,
    multiple_product_id VARCHAR(100),
    price       INTEGER,
    vat         INTEGER,
    valuta      VARCHAR(10),
    productcount INTEGER,
    receipt_nr  INTEGER,
    email       VARCHAR(300),
    phone       VARCHAR(300),
    salt        VARCHAR(128),
    password    VARCHAR(300),
    name        VARCHAR(300),
    company     VARCHAR(300),
    address     VARCHAR(500),
    city        VARCHAR(500),
    zip         VARCHAR(100),
    country     VARCHAR(100),
    shipping    INTEGER,
    payment_received VARCHAR(100),
    shipped     VARCHAR(100),
    modified timestamp not null default (STRFTIME('%s', 'now')),
    creation timestamp not null default (STRFTIME('%s', 'now'))
  );""", []):
    error("Buy plugin: Could not create table")


  info("Buy plugin: Creating folder for receipts")
  discard existsOrCreateDir(storageEFS / "receipts")