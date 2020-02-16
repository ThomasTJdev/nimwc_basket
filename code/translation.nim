# Copyright 2019 - Thomas T. Jarløv
import logging, strutils, tables

when defined(postgres): import db_postgres
else:                   import db_sqlite

# Translation
const mainTrans* = """
receipt_EN = Receipt
receipt_DK = Faktura

receipts_EN = Receipts
receipts_DK = Fakturaer

price_EN = Price
price_DK = Pris

pricePer_EN = Price/stk
pricePer_DK = Pris/styk

vat_EN = VAT
vat_DK = Moms

vatS_EN = VAT
vatS_DK = moms

incl_EN = Incl.
incl_DK = Inkl.

inclVat_EN = incl. VAT
inclVat_DK = inkl. moms

buy_EN = Buy
buy_DK = Køb

next_EN = Next
next_DK = Videre

back_EN = Back
back_DK = Tilbage

customerData_EN = Customer information
customerData_DK = Kundeinformation

name_EN = Name
name_DK = Navn

email_EN = Email
email_DK = Email

password_EN = Password (to access your receipts online)
password_DK = Kodeord (for at tilgå dine fakturaer online)

numberOfProducts_EN = Number of goods (more than 10 contact)
numberOfProducts_DK = Antal varer (mere end 10 kontakt)

priceVat_EN = Price incl. VAT
priceVat_DK = Pric inkl. moms

hereofVat_EN = Hereof is VAT
hereofVat_DK = Heraf udgør moms

phone_EN = Phone
phone_DK = Telefon

address_EN = Address
address_DK = Adresse

zip_EN = Zipcode
zip_DK = Postnummer

city_EN = City
city_DK = By (bynavn)

country_EN = Country
country_DK = Land

companyOptional_EN = Company (optional)
companyOptional_DK = Firma (frivillig)

companyIdOptional_EN = Company ID (optional)
companyIdOptional_DK = Firma CVR (frivillig)

company_EN = Company
company_DK = Firma

delivery_EN = Delivery
delivery_DK = Forsendelse

productInfo_EN = Product info
productInfo_DK = Vareinformation

product_EN = Product
product_DK = Vare

quantity_EN = Quantity
quantity_DK = Antal

priceNoVat_EN = Price (w/o VAT)
priceNoVat_DK = Pris (u. moms)

deliveryPriceNoVat_EN = Delivery price (w/o VAT)
deliveryPriceNoVat_DK = Leveringspris (u. moms)

totalPriceWithVat_EN = Total price (w. Vat)
totalPriceWithVat_DK = Samlet pris (m. moms)

acceptConditions_EN = When pressing "Buy" you accept the <a href="/basket/conditions" target="_blank">terms and conditions</a>. There will be generated a receipt.
acceptConditions_DK = Ved at trykke "Køb" bekræfter du en købsaftale og <a href="/basket/conditions" target="_blank">handelsbetingelserne</a>. Der vil blive genereret en faktura.

sendRecieptEmail_EN = Send email with receipt to your email
sendRecieptEmail_DK = Send email med fakturaen

congratulations_EN = <h1>Congratulation!</h1><p>You just need to pay, and then your order is on the way.</p><p>We have sent you an email with your receipt. You can also download your receipt below.</p>
congratulations_DK = <h1>Tillykke!</h1><p>Du skal nu blot betale for varen, og så er den på vej til dig.</p><p>Vi har sendt dig en email med fakturaen. Du kan også downloade din faktura nedenfor.</p>

accessReceipts_EN = Access your receipts
accessReceipts_DK = Få adgang til dine fakturaer

insertUserPwd_EN = Insert your email and password below.
insertUserPwd_DK = Indsæt din email og dit password nedenfor.

seeReceipts_EN = See receipts
seeReceipts_DK = Se fakturaer

creation_EN = Creation
creation_DK = Oprettet

payment_EN = Payment
payment_DK = Betaling

posted_EN = Shipped
posted_DK = Afsendt

download_EN = Download
download_DK = Download

paymentRegistered_EN = Payment registered
paymentRegistered_DK = Betaling registreret

paymentAwaiting_EN = Payment awaiting
paymentAwaiting_DK = Betaling afventer

paymentReady_EN = Ready for payment
paymentReady_DK = Klar til betaling

paymentCanceled_EN = Canceled
paymentCanceled_DK = Annulleret

products_EN = Products
products_DK = Varer

shippingDetails_EN = Shipping details
shippingDetails_DK = Leveringsdetaljer

clickToBuy_EN = Click on a product to buy it.
clickToBuy_DK = Klik på et produkt for at købe det.

sender_EN = Sender
sender_DK = Afsender

receiver_EN = Receiver
receiver_DK = Modtager

buyOf_EN = Buy of
buyOf_DK = Køb af

dateForOrder_EN = The receipt has been generated the
dateForOrder_DK = Fakturaen er genereret den

description_EN = Description
description_DK = Beskrivelse

unitPrice_EN = Unit price
unitPrice_DK = Enhedspris

totalWoVat_EN = Total w/o VAT
totalWoVat_DK = I alt ekskl. moms:

totalWVat_EN = Total w. VAT
totalWVat_DK = I alt inkl. moms:

mailSubjectCongrats_EN = $1: Receipt for $2
mailSubjectCongrats_DK = $1: Faktura for $2

mailMsgCongrats_EN = <p>Hey $1</p> <p>Thank you for your purchase.</p> <p>You just need to pay your receipt, and then we'll send you product.</p> <hr> <p><b>Product:</b> $2</p> <p><b>Price:</b> $3</p> <p><b>Receipt nr.:</b> $8</p> <p> <b>Payment:</b> <br> $4 </p> <hr> <p>You can find all your receipts here: <a href="$5">Login to receipts</a></p> <p>If you have any question regarding your receipt or the delivery, you can always contact us at <a href="mailto:$6">$6</a></p> <p>Kind regards<br>$7</p>
mailMsgCongrats_DK = <p>Hej $1</p> <p>Mange tak for dit køb.</p> <p>Du skal blot betale fakturaen, og herefter vil dit køb blive afsendt.</p> <hr> <p><b>Vare:</b> $2</p> <p><b>Pris:</b> $3</p> <p><b>Faktura nr.:</b> $8</p> <p> <b>Betaling:</b> <br> $4 </p> <hr> <p>Du kan finde alle dine fakturaer på: <a href="$5">Login til fakturaer</a></p> <p>Hvis du har spørgsmål til din faktura eller forsendelsen, kan du altid kontakte os på <a href="mailto:$6">$6</a></p> <p>Mvh<br>$7</p>

mailSubjectShipped_EN = $1: Your order has been shipped
mailSubjectShipped_DK = $1: Din ordre er afsendt

mailMsgShipped_EN = <p>Hey $1</p> <p>You order has now been dispatched. We hope you'll be happy for it.</p> <hr> <p>You can find all your receipts here: <a href="$2">Login to receipts</a></p> <p>If you have any question regarding your receipts or the delivery, you can always contact us af <a href="mailto:$3">$3</a></p> <p>Kind regards<br>$4</p>
mailMsgShipped_DK = <p>Hej $1</p> <p>Din ordre er nu afsendt. Vi håber, at du bliver glad for din vare.</p> <hr> <p>Du kan finde alle dine fakturaer på: <a href="$2">Login til fakturaer</a></p> <p>Hvis du har spørgsmål til din faktura eller forsendelsen, kan du altid kontakte os på <a href="mailto:$3">$3</a></p> <p>Mvh<br>$4</p>
"""


var transLang = "EN"
var langTable*: Table[string, string]

proc basketLangGen*(db: DbConn): Table[string, string] =
  ## Create table from language file
  let tmp = getValue(db, sql("SELECT language FROM basket_settings;")).substr(0,1)
  transLang = if tmp == "": "EN" else: tmp
  var trans = getValue(db, sql("SELECT translation FROM basket_settings;"))
  exec(db, sql("UPDATE basket_settings SET translation = ?;"), mainTrans)
  trans = mainTrans

  result = initTable[string, string]()
  for line in trans.splitLines:
    if line.len < 1 and line.substr(0, 0) != "[": continue
    var chunks = split(line, " = ")
    if chunks.len != 2:
      continue

    result[chunks[0]] = chunks[1]

  if result.len < 1: warn("Plugin Basket: Language file was empty!")


proc basketLang*(identifier: string, lang = transLang): string =
  ## Returns the translation

  try:
    return langTable[identifier & "_" & lang]
  except:
    warn("Plugin Basket: Error while retrieving language item: " & identifier & "_" & lang)
    warn(langTable)
    return ""