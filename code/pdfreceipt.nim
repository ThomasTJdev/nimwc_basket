# Copyright 2020 - Thomas T. Jarløv

import datetime2human, math, strutils, db_sqlite, times, os
import unicode except strip
import nimPDF/nimPDF
import translation


#template fontH1() =
#  doc.setFont("Roboto", {FS_BOLD}, 12)

template fontH2() =
  doc.setFont("Roboto", {FS_BOLD}, 10)

#template fontH3() =
#  doc.setFont("Roboto", {FS_BOLD}, 8)

template fontH4() =
  doc.setFont("Roboto", {FS_BOLD}, 6)

template fontStdBold() =
  doc.setFont("Roboto", {FS_BOLD}, 4, ENC_UTF8)

template fontStd() =
  doc.setFont("Roboto", {FS_REGULAR}, 3.5, ENC_UTF8)

template fontSmall() =
  doc.setFont("Roboto", {FS_REGULAR}, 3.5, ENC_UTF8)

proc draw_rect(doc: PDF, x, y, w, h: float64, label:string) =
  doc.drawRect(x, y - 1, w, h)
  doc.drawText(x + 2, y + 5, label)


proc drawRectHeading(doc: PDF, x, y, w, h: float64, label:string) =
  ## Draw cell heading
  doc.setFillColor(initRGB("21,59,101"))
  doc.setStrokeColor(initRGB("black"))
  doc.drawRect(x, y - 1, w, h)
  doc.fillAndStroke()

  doc.setFillColor(initRGB("white"))
  doc.drawText(x + 2, y + 5, label)
  doc.fill()


proc cellDrawRectTextInsert(doc: PDF, x, yLoop: float64, textRaw: string, lastLine: bool, isCell=true) =
  const noneHypenChars = [" ", ".", ",", ":", ";", "-", "/", "(", ")", "!", "?", "[", "]", ""]

  #let text = toRunes(textRaw)
  let text = toRunes(textRaw)
  let runeLength = runeLen(textRaw)
  let textString = if not lastLine: runeSubStr($text, 0, runeLength-1) else: runeSubStr($text, 0, runeLength)

  let lastTmp1 = runeSubStr($text, runeLength-2, 1)
  let lastTmp2 = runeSubStr($text, runeLength-1, 1)

  if lastTmp1 notin noneHypenChars and lastTmp2 notin noneHypenChars and lastTmp1 != "" and lastTmp2 != "" and not lastLine:
    doc.drawText(x, yLoop, strutils.strip(textString) & "-")

  else:
    doc.drawText(x, yLoop, strutils.strip(textString))



proc cellDrawRectText(doc: PDF, x, y, w, h: float64, textRaw: string, isCell=true) =
  ## Draw cell and insert text
  ##
  ## This proc uses runes to do correct formatting of special
  ## chars such as æøå. The line length will be calculated as
  ## a rune-len:
  ##    assert "HEJÆØÅ".len == 9
  ##    assert toRunes("HEJÆØÅ").len == 6
  ##
  ## For the runes splitting of lines the runeSubStr is used.
  ## The calculation of hyphens inserted into breaking lines
  ## are performed in `cellDrawRectTextInsert`.
  ##
  ## If you are inserting normal text, set isCell=false and
  ## subtract 2int from the x, since a cell is inserting a space on 2.

  const lineHeight = 5.0
  let runeTextInChars = repeat("A", toRunes(textRaw).len)
  let runeTextInCharsLen = runeTextInChars.len
  let textReplaceRunes = multiReplace(textRaw, [("æ", "a"), ("ø", "o"), ("å", "a"), ("Æ", "A"), ("Ø", "O"), ("Å", "A")])
  let textReplaceRunesLen = textReplaceRunes.len
  let widthNeed = doc.getTextWidth(textReplaceRunes)
  var yLoop = y + 5

  let xVal = if isCell: x + 2 else: x

  # Print single line text
  if w > widthNeed and "\n" notin textRaw:
    doc.drawText(xVal, y + 5, textRaw)

  # Print multi line text less width than paper
  elif w > widthNeed:
    for printLine in split(textRaw, "\n"):
      # Cant insert empty line
      if printLine == "" or printLine == "\n":
        doc.drawText(xVal, yLoop, " ")
      else:
        doc.drawText(xVal, yLoop, strutils.strip(printLine))
      yLoop += lineHeight

  # Print multi line
  else:
    let wCalc = w - 6 #12
    let lineLength = widthNeed / wCalc #  2.14 (line specific)

    let lineCharLengthOrig = toInt(toFloat(textReplaceRunesLen) / lineLength) # - 3 # to ceil() ???

    var firstRun = true
    var lastCharCount: int
    var lineWorking: bool

    for printLine in split(textRaw, "\n"):
      let printLineRuneLen = runeLen(printLine)
      lineWorking = true
      firstRun = true
      lastCharCount = 0

      # Cant insert empty line
      if printLine == "" or printLine == "\n":
        cellDrawRectTextInsert(doc, xVal, yLoop, " ", true)
        yLoop += lineHeight
        continue

      # Loop through line until all of it is printed
      while lineWorking:
        var lineCharLength = lineCharLengthOrig
        var lastLine = false

        var textToInsert = runeSubStr(printLine, lastCharCount, lineCharLength+1)

        # Check if real length is longer than available width
        let tmptextReplaceRunes = multiReplace(textToInsert, [("æ", "a"), ("ø", "o"), ("å", "a"), ("Æ", "A"), ("Ø", "O"), ("Å", "A")])
        let tmpwidthNeed = doc.getTextWidth(tmptextReplaceRunes)
        if (wCalc - 6) < tmpwidthNeed:
          let widthDiff = wCalc / tmpwidthNeed
          let charsPoss = toInt(toFloat(runeLen(tmptextReplaceRunes)) * widthDiff)
          lineCharLength = charsPoss - 5
          textToInsert = runeSubStr(printLine, lastCharCount, lineCharLength+1)

        else:
          lastLine = if printLineRuneLen < (lastCharCount+lineCharLength): true else: false

        cellDrawRectTextInsert(doc, xVal, yLoop, textToInsert, lastLine)

        # Add count to last char in line
        if firstRun:
          # First run shall not add +1 to starting char
          lastCharCount += lineCharLength
          firstRun = false
        else:
          lastCharCount += lineCharLength #+1

        # Increase line Y
        yLoop += lineHeight

        # Check if printing is done
        if lastCharCount >= printLineRuneLen:
          lineWorking = false

  if isCell:
    doc.drawRect(x, y - 1, w, h)


proc pageCheckText(doc: PDF, size: PageSize, pageHeight, pageWidth, y: float64, text: string): bool =
  const lineHeight = 5.0
  const prefH = 10.0

  let widthNeed = doc.getTextWidth(text)  # e.g. 343
  let wCalc = pageWidth - 12
  let lines = ceil(widthNeed / wCalc)     # e.g. 3 (round up line)
  if ((lineHeight * lines) + (prefH - lineHeight) + y) > pageHeight-25:
    doc.addPage(size, PGO_PORTRAIT)
    doc.setFillColor(initRGB("black"))
    doc.setFont("Roboto", {FS_REGULAR}, 3.5, ENC_UTF8)
    return true


proc pageCheckHeight(doc: PDF, size: PageSize, pageHeight, y, h: float64): bool =
  if pageHeight-25 < (y + h):
    doc.addPage(size, PGO_PORTRAIT)
    doc.setFillColor(initRGB("black"))
    doc.setFont("Roboto", {FS_REGULAR}, 3.5, ENC_UTF8)
    return true


proc rowHeightCalc(doc: PDF, prefH, widthAvai: float64, text: string): float64 =
  ## Calculate the height of the text based on the available width.
  ## If text does not need new line, return preferred height, otherwise
  ## calculate the height.
  const lineHeight = 5.0

  # Check if theres any newlines in text "\n"
  if countLines(text) > 1:
    # Split each new line into seq
    let splitLines = split(text, "\n")
    # Available width
    let wCalc = widthAvai - 6
    var lines: float

    # Loop through each line
    for line in splitLines:
      if line == "" or line == "\n":
        lines += 1
        continue
      let widthNeed = doc.getTextWidth(line)
      if widthAvai > widthNeed:
        lines += 1
      else:
        lines += ceil(widthNeed / wCalc)

    return ((lineHeight * lines) + (prefH - lineHeight))


  let widthNeed = doc.getTextWidth(text)  # e.g. 343
  if widthAvai > widthNeed:               # e.g. 160 > 343
    return prefH
  else:
    let wCalc = widthAvai - 12
    let lines = ceil(widthNeed / wCalc)   # e.g. 3 (round up line)
    return ((lineHeight * lines) + (prefH - lineHeight))


proc drawRow(doc: PDF, productName, buyNumber, buyPrice, buyPricetotal, buyVatTotal, buyValuta: string, y, x, c1, c2, c3, c4, c5: float64): float64 =
  ## Draw row
  ##

  var rowIndent = x
  # R1 - init
  doc.setFillColor(initRGB("black"))
  doc.setFont("Roboto", {FS_REGULAR}, 3.5, ENC_UTF8)

  # R1 - Row height
  # Text align left
  let row1Height = rowHeightCalc(doc, 10, c1 - 5, productName)
  # R1 - Col 1
  doc.cellDrawRectText(rowIndent, y, c1, row1Height, productName);
  doc.stroke()
  rowIndent += c1

  # R1 - Col 2
  # Center result
  let c2Width = doc.getTextWidth(buyNumber)
  let c2WidthCheck = rowIndent + ((c2 - c2Width) / 2)
  doc.drawText(c2WidthCheck, y + 5, buyNumber)
  doc.cellDrawRectText(rowIndent, y, c2, row1Height, " ");
  doc.stroke()
  rowIndent += c2

  # R1 - Col 3
  # Text align right
  let c3Width = doc.getTextWidth(buyPrice & " " & buyValuta)
  let c3WidthCheck = rowIndent + c3 - c3Width - 5
  doc.drawText(c3WidthCheck, y + 5, buyPrice & " " & buyValuta)
  doc.cellDrawRectText(rowIndent, y, c3, row1Height, " ");
  doc.stroke()
  rowIndent += c3

  # R1 - Col 4
  # Text align right
  let c4Width = doc.getTextWidth(buyPricetotal & " " & buyValuta)
  let c4WidthCheck = rowIndent + c4 - c4Width - 5
  doc.drawText(c4WidthCheck, y + 5, buyPricetotal & " " & buyValuta)
  doc.cellDrawRectText(rowIndent, y, c4, row1Height, " ");
  doc.stroke()
  rowIndent += c4

  # R1 - Col 5
  # Text align right
  let c5Width = doc.getTextWidth(buyVatTotal & " " & buyValuta)
  let c5WidthCheck = rowIndent + c5 - c5Width - 5
  doc.drawText(c5WidthCheck, y + 5, buyVatTotal & " " & buyValuta)
  doc.cellDrawRectText(rowIndent, y, c5, row1Height, " ");
  doc.stroke()
  rowIndent += c5
  # R1 - Ready next wrow
  return row1Height


proc content(db: DbConn, doc: PDF, id, email, multi, cusmsg: string) =
  ## PDF content

  let buyInfo  = getRow(db, sql("SELECT price, vat, productcount, email, name, receipt_nr, payment_received, company, address, city, creation, valuta, shipping, product_id, zip, country, phone, multiple_product_id, multiple_product_count, companyid FROM basket_purchase WHERE id = ? AND email = ?"), id, email)
  #[
    0) price,
    1) vat,
    2) productcount,
    3) email,
    4) name,
    5) receipt_nr,
    6) payment_received,
    7) company,
    8) address,
    9) city
    10) creation
    11) valuta
    12) shipping
    13) product_id
    14) zip
    15) country
    16) phone
    17) multi ID
    18) multi count
  ]#

  # Basket
  var
    buyPrice: string
    buyVat: string
    buyNumber: string
    buyMultiNumber: string
    buyDate: string
    buyValuta: string
    buyship: string
    buyProductID: string
    buyMultiID: string

    productTotalVat: int
    productTotalPrice: int
    productTotal: int

    buyInfoMulti: Row

    # Product
    productName: string
    productDesr: string

    # Ship
    shipName: string
    shipDesr: string
    shipValuta: string
    shipPrice: int
    shipVat: int
    shipTotalPrice: int

    # Price
    totalPrice: int
    totalVat: int
    total: int

  let
    cusEmail     = buyInfo[3]
    cusName      = buyInfo[4]
    cusCompany   = buyInfo[7]
    cusCompanyId = buyInfo[19]
    cusAddress   = buyInfo[8]
    cusCity      = buyInfo[9]
    cusZip       = buyInfo[14]
    cusCountry   = buyInfo[15]
    cusPhone     = buyInfo[16]


  buyPrice  = buyInfo[0]
  buyVat    = buyInfo[1]
  buyDate   = buyInfo[10]
  buyValuta = buyInfo[11]
  buyShip   = buyInfo[12]


  if multi != "true":
    buyNumber    = buyInfo[2]
    buyProductID = buyInfo[13]

    productTotalVat   = parseInt(buyVat) * parseInt(buyNumber)
    productTotalPrice = parseInt(buyPrice) * parseInt(buyNumber)
    productTotal      = productTotalVat + productTotalPrice

    # Product
    let productData = getRow(db, sql("SELECT productName, productDescription FROM basket_products WHERE id = ?"), buyInfo[13])

    productName = productData[0]
    productDesr = productData[1]

  else:
    buyMultiID     = buyInfo[17]
    buyMultiNumber = buyInfo[18]

    let productCount = split(buyMultiNumber, ",")
    var count: int

    for i in split(buyMultiID, ","):
      buyInfoMulti = getRow(db, sql("SELECT productName, productDescription, price, vat FROM basket_products WHERE id = ?"), i)

      productTotalPrice += parseInt(buyInfoMulti[2]) * parseInt(productCount[count])
      productTotalVat   += parseInt(buyInfoMulti[3]) * parseInt(productCount[count])

      count += 1

    productTotal = productTotalVat + productTotalPrice


  # Customer info
  var customerInfo = cusAddress & "\n" & cusZip & " " & cusCity & "\n" & cusCountry & "\n\nAtt.: " & cusName & "\n" & cusEmail
  if cusPhone != "":
    customerInfo = customerInfo & "\n" & cusPhone
  if cusCompanyId != "":
    customerInfo = cusCompanyId & "\n" & customerInfo
  if cusCompany != "":
    customerInfo = cusCompany & "\n" & customerInfo


  # Shipping
  if buyShip != "" and buyShip == "0":
    let shipData = getRow(db, sql("SELECT name, description, price, vat, valuta FROM basket_shipping WHERE id = ?"), buyShip)
    shipName    = shipData[0]
    shipDesr    = shipData[1]
    shipPrice   = parseInt(shipData[2])
    shipVat     = parseInt(shipData[3])
    shipValuta  = shipData[4]

    shipTotalPrice = shipPrice + shipVat

  # Your company data
  let
    mainInfo = getRow(db, sql("SELECT receipt_nr_next, companyName, companyDescription, paymentMethod FROM basket_settings"))
    companyName = mainInfo[1]
    companyDesr = mainInfo[2]
    paymentMeth = mainInfo[3]

  # Total price
  totalPrice = productTotalPrice + shipPrice
  totalVat   = productTotalVat + shipVat
  total      = totalPrice + totalVat



  # Setup PDF
  let size = getSizeFromName("A4")

  # Setup main w/h
  const yOrig = 25.0
  var y = yOrig                       # Start from top
  var x = 15.0                        # Indent
  let pageWidth = size.width.toMM - x # Page width exluded margins
  let pageHeight = size.height.toMM   # Page height exluded margins

  # Set page
  doc.addPage(size, PGO_PORTRAIT)

  # --------------------------------
  # Content
  # --------------------------------

  # Company name (top)
  fontH2()
  let widthNeed = doc.getTextWidth(companyName)
  let dispSpace = (pageWidth - widthNeed) / 2
  doc.drawText(dispSpace, y, companyName)
  y += 7.0

  # Draw line beneath heading
  doc.setLineWidth(0.5)
  doc.moveTo(x, y)
  doc.lineTo(pageWidth, y)
  doc.stroke()
  y += 10.0

  # Heading
  fontH4()
  doc.drawText(15, y, basketLang("receipt") & " - " & buyInfo[5])
  y += 10.0


  # Company description and Customer address
  let columnWidth = pageWidth / 2.5
  let companyDesrHeight = rowHeightCalc(doc, 10, columnWidth, companyDesr)
  let customerInfoHeight = rowHeightCalc(doc, 10, columnWidth, customerInfo)
  let addressHeight = if companyDesrHeight > customerInfoHeight: companyDesrHeight else: customerInfoHeight

  # Company description
  fontStdBold()
  doc.drawText(15, y, basketLang("sender") & ":")
  y += 3.0

  fontStd()
  doc.cellDrawRectText(15, y, columnWidth, addressHeight, companyDesr);
  doc.stroke()

  # Subtrack 3 from y, due to levelling with sender
  fontStdBold()
  doc.drawText(columnWidth + (columnWidth / 2), y - 3.0, basketLang("receiver") & ":")

  fontStd()
  doc.cellDrawRectText(columnWidth + (columnWidth / 2), y, columnWidth, addressHeight, customerInfo);
  doc.stroke()

  y += addressHeight + 15.0


  # Second heading
  fontH4()
  if multi != "true":
    doc.drawText(15, y, basketLang("buyOf") & ": " & productName)
  else:
    doc.drawText(15, y, basketLang("buyOf") & ":")
  y += 10.0

  fontSmall()

  # Date
  doc.drawText(15, y, basketLang("dateForOrder") & ": " & epochDate(buyDate, "YYYY-MM-DD HH:mm"))
  y += 5.0

  # Description
  if multi != "true":
    let desr = if cusmsg == "": productDesr else: cusmsg & "\n\n" & productDesr
    let productDesrHeight = rowHeightCalc(doc, 10, pageWidth - 5, desr)
    doc.cellDrawRectText(15, y, (pageWidth - 5), productDesrHeight, desr, isCell=false)
    y += 3.0 + productDesrHeight

  elif cusmsg != "":
    let productDesrHeight = rowHeightCalc(doc, 10, pageWidth - 5, cusmsg)
    doc.cellDrawRectText(15, y, (pageWidth - 5), productDesrHeight, cusmsg, isCell=false)
    y += 3.0 + productDesrHeight

  fontStd()

  # Purchase details
  let rowHeadingHeight = 10.0
  var rowHeadingIndent = x
  let rowHeadingWidth = (pageWidth - 15) / 11
  let c1 = rowHeadingWidth * 4.6
  let c2 = rowHeadingWidth * 1
  let c3 = rowHeadingWidth * 1.8
  let c4 = rowHeadingWidth * 1.8
  let c5 = rowHeadingWidth * 1.8

  # Insert row headings
  fontStdBold()
  # Description
  doc.drawRectHeading(rowHeadingIndent, y, c1, rowHeadingHeight, basketLang("description"));
  doc.stroke()
  rowHeadingIndent += c1
  # Number
  doc.drawRectHeading(rowHeadingIndent, y, c2, rowHeadingHeight, basketLang("quantity"));
  doc.stroke()
  rowHeadingIndent += c2
  # Price (without vat)
  doc.drawRectHeading(rowHeadingIndent, y, c3, rowHeadingHeight, basketLang("unitPrice"));
  doc.stroke()
  rowHeadingIndent += c3
  # Price x Number (without vat)
  doc.drawRectHeading(rowHeadingIndent, y, c4, rowHeadingHeight, basketLang("price"));
  doc.stroke()
  rowHeadingIndent += c4
  # VAT
  doc.drawRectHeading(rowHeadingIndent, y, c5, rowHeadingHeight, basketLang("vat"));
  doc.stroke()
  y += rowHeadingHeight #+ 5

  # Insert purchase details
  if multi != "true":
    y += drawRow(doc, productName, buyNumber, buyPrice, $productTotalPrice, $productTotalVat, buyValuta, y, x, c1, c2, c3, c4, c5)
  else:
    let productCount = split(buyMultiNumber, ",")
    var count: int

    for i in split(buyMultiID, ","):
      buyInfoMulti = getRow(db, sql("SELECT productName, productDescription, price, vat, valuta FROM basket_products WHERE id = ?"), i)
      productTotalPrice = parseInt(buyInfoMulti[2]) * parseInt(productCount[count])
      productTotalVat   = parseInt(buyInfoMulti[3]) * parseInt(productCount[count])

      # Use pageCheckText
      y += drawRow(doc, buyInfoMulti[0], productCount[count], buyInfoMulti[2], $productTotalPrice, $productTotalVat, buyInfoMulti[4], y, x, c1, c2, c3, c4, c5)

      count += 1

  # Insert shipping details
  if buyShip != "" and buyShip == "0":
    y += drawRow(doc, shipName, "1", $shipPrice, $shipPrice, $shipVat, shipValuta, y, x, c1, c2, c3, c4, c5)

  y += 7.0


  # Total pris
  fontStd()

  # Indent for sum
  let rowHeadingWidth10 = (pageWidth - 15) / 10
  let csum1 = rowHeadingWidth * 5
  let csum2 = rowHeadingWidth * 1
  let csum3 = rowHeadingWidth * 2
  let csum4 = rowHeadingWidth * 2

  # Price info
  let price1Width = doc.getTextWidth(basketLang("totalWoVat"))
  let price1WidthCheck = (15 + rowHeadingWidth10 * 6.3) + csum3 - price1Width
  doc.drawText(price1WidthCheck, y, basketLang("totalWoVat"))

  # Price number
  let price2Width = doc.getTextWidth($totalPrice & " " & buyValuta)
  let price2WidthCheck = (15 + rowHeadingWidth10 * 8) + csum4 - price2Width - 2
  doc.drawText(price2WidthCheck, y, $totalPrice & " " & buyValuta)
  y += 5.0


  # VAT info
  let vat1Width = doc.getTextWidth(basketLang("vat"))
  let vat1WidthCheck = (15 + rowHeadingWidth10 * 6.3) + csum3 - vat1Width - 5
  doc.drawText(vat1WidthCheck, y, basketLang("vat"))

  # VAT number
  if buyVat == "0" and $shipVat == "0":
    let vat2Width = doc.getTextWidth("0 " & buyValuta)
    let vat2WidthCheck = (15 + rowHeadingWidth10 * 8) + csum4 - vat2Width - 2
    doc.drawText(vat2WidthCheck, y, "0 " & buyValuta)
  else:
    let vat2Width = doc.getTextWidth($totalVat & " " & buyValuta)
    let vat2WidthCheck = (15 + rowHeadingWidth10 * 8) + csum4 - vat2Width - 2
    doc.drawText(vat2WidthCheck, y, $totalVat & " " & buyValuta)
  y += 3.0

  # Line before total price including vat
  doc.setLineWidth(0.2)
  doc.moveTo(15 + rowHeadingWidth10 * 6, y)
  doc.lineTo(15 + rowHeadingWidth10 * 10 , y)
  doc.stroke()
  y += 5.0

  # Price w. VAT info
  fontStdBold()
  let sum1Width = doc.getTextWidth(basketLang("totalWVat"))
  let sum1WidthCheck = (15 + rowHeadingWidth10 * 6.3) + csum3 - sum1Width - 5
  doc.drawText(sum1WidthCheck, y, basketLang("totalWVat"))

  # Price w. VAT number
  let sum2Width = doc.getTextWidth($total & " " & buyValuta)
  let sum2WidthCheck = (15 + rowHeadingWidth10 * 8) + csum4 - sum2Width - 2
  doc.drawText(sum2WidthCheck, y, $total & " " & buyValuta)
  y += 3.0

  # Line after total price including vat
  doc.setLineWidth(0.2)
  doc.moveTo(15 + rowHeadingWidth10 * 6, y)
  doc.lineTo(15 + rowHeadingWidth10 * 10 , y)
  doc.stroke()
  y += 7.0


  # Number
  fontH4()
  doc.drawText(15, y, basketLang("payment") & ":")
  y += 7.0

  fontStd()
  let paymentMethHeight = rowHeightCalc(doc, 10, pageWidth - 5, paymentMeth)
  if pageCheckHeight(doc, size, pageHeight, y, paymentMethHeight): y = 25
  doc.cellDrawRectText(15, y, (pageWidth - 5), paymentMethHeight, paymentMeth, isCell=false)
  y += 7.0 + paymentMethHeight



proc pdfBuyGenerator*(db: DbConn, id, path, email, multi, cusmsg: string) =
  ## Generate PDF with machine safety

  # Setup doc options
  var opts = newPDFOptions()
  opts.addFontsPath(splitPath(currentSourcePath())[0].replace("/code", "") / "fonts")
  #opts.addImagesPath(splitPath(currentSourcePath())[0] / "images")

  # Setup document
  var doc = newPDF(opts)

  # Generate content

  content(db, doc, id, email, multi, cusmsg)

  if not doc.writePDF(path):
    echo "ERROR"
