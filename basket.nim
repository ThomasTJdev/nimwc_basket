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
  strutils,
  tables

from times import epochTime

import ../../nimwcpkg/constants/constants
import ../../nimwcpkg/emails/emails
import ../../nimwcpkg/files/files
import ../../nimwcpkg/passwords/passwords
import ../../nimwcpkg/plugins/plugins
import ../../nimwcpkg/webs/captchas

import code/pdfreceipt
export pdfBuyGenerator

import code/translation
export basketLangGen, basketLang, langTable

import code/translation

import code/basket_utils
export getProductData

when defined(postgres): import db_postgres
else:                   import db_sqlite

let (basketN, basketV*, basketD, basketU) = pluginGetDetails("basket")
proc pluginInfo() =
  echo " "
  echo "--------------------------------------------"
  echo "  Package:      " & basketN
  echo "  Version:      " & basketV
  echo "  Description:  " & basketD
  echo "  URL:          " & basketU
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

proc parseIntSafe(str: string): int =
  try:
    return parseInt(str)
  except:
    return 0

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
  var image = newAttachment(readFile(filepath), filename = basketLang("receipt") & "_" & receiptNr & ".pdf")
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

  info("Basket plugin: Updating database with Basket table if not exists")

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
    mailAdminBought     VARCHAR(10),
    languages           TEXT,
    language            VARCHAR(10),
    translation         TEXT,
    modified timestamp not null default (STRFTIME('%s', 'now')),
    creation timestamp not null default (STRFTIME('%s', 'now'))
  );""", []):
    error("Basket plugin: Could not create table")

  if getValue(db, sql("SELECT receipt_nr_next FROM basket_settings;")) == "":
    exec(db, sql("INSERT INTO basket_settings (receipt_nr_next, companyName, companyDescription, paymentMethod, countries, language, languages, translation) VALUES (?, ?, ?, ?, ?, ?, ?, ?)"), "1", "", "", "", "Denmark", "EN", "EN", mainTrans)


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
    active              INTEGER,
    modified timestamp not null default (STRFTIME('%s', 'now')),
    creation timestamp not null default (STRFTIME('%s', 'now'))
  );""", []):
    error("Basket plugin: Could not create table")


  if not db.tryExec(sql"""
  create table if not exists basket_shipping (
    id INTEGER   primary key,
    name         TEXT NOT NULL,
    description  TEXT,
    price        INTEGER,
    vat          INTEGER,
    valuta       VARCHAR(10),
    maxItems     INTEGER,
    minItems     INTEGER,
    modified timestamp not null default (STRFTIME('%s', 'now')),
    creation timestamp not null default (STRFTIME('%s', 'now'))
  );""", []):
    error("Basket plugin: Could not create table")


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
    receipt_nr  INTEGER,
    email       VARCHAR(300),
    phone       VARCHAR(300),
    salt        VARCHAR(128),
    password    VARCHAR(300),
    name        VARCHAR(300),
    company     VARCHAR(300),
    companyid   VARCHAR(300),
    address     VARCHAR(500),
    city        VARCHAR(500),
    zip         VARCHAR(100),
    country     VARCHAR(100),
    shipping    INTEGER,
    shippingDetails VARCHAR(1000),
    shippingPrice VARCHAR(100),
    shippingVat VARCHAR(100),
    payment_received VARCHAR(100),
    shipped     VARCHAR(100),
    modified timestamp not null default (STRFTIME('%s', 'now')),
    creation timestamp not null default (STRFTIME('%s', 'now'))
  );""", []):
    error("Basket plugin: Could not create table")

  if not db.tryExec(sql"""
  create table if not exists basket_purchase_products (
    id INTEGER primary key,
    purchase_id INTEGER,
    product_id  INTEGER,
    price       INTEGER,
    vat         INTEGER,
    valuta      VARCHAR(10),
    productcount INTEGER,
    modified timestamp not null default (STRFTIME('%s', 'now')),
    creation timestamp not null default (STRFTIME('%s', 'now')),

    foreign key (purchase_id) references basket_purchase(id)
  );""", []):
    error("Basket plugin: Could not create table")


  info("Basket plugin: Creating folder for receipts")
  discard existsOrCreateDir(storageEFS / "receipts")


  info("Basket plugin: Initializing translations")
  langTable = basketLangGen(db)


  info("Basket plugin: Copying UI JS-file if not exists or newer version available")
  when defined(dev):
    copyFile(getAppDir().replace("nimwcpkg") / "plugins/basket/public/basket_ui.js", getAppDir().replace("nimwcpkg") / "public/js/basket_ui_" & basketV & ".js")
    info("Basket plugin: New JS file copied to JS-folders")
  else:
    if not fileExists(getAppDir().replace("nimwcpkg") / "public/js/basket_ui_" & basketV & ".js"):
      copyFile(getAppDir().replace("nimwcpkg") / "plugins/basket/public/basket_ui.js", getAppDir().replace("nimwcpkg") / "public/js/basket_ui_" & basketV & ".js")
      info("Basket plugin: New JS file copied to JS-folders")