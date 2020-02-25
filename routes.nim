
  #[
    Settings admin: Pages
  ]#



  get "/basket/settings":
    createTFD()
    if not c.loggedIn or c.rank notin [Admin, Moderator]:
      redirect("/")

    resp genMain(c, genBuy(db))


  #[
    Settings admin: Edit settings
  ]#
  # Edit company
  get "/basket/company/edit":
    createTFD()
    if not c.loggedIn or c.rank notin [Admin, Moderator]:
      redirect("/")

    resp genMain(c, genBasketCompany(db))

  # Edit company
  post "/basket/company/edit":
    createTFD()
    if not c.loggedIn or c.rank notin [Admin, Moderator]:
      redirect("/")

    let mailOrder = if @"mailOrder" == "on": "true" else: "false"
    let mailShipped = if @"mailShipped" == "on": "true" else: "false"
    let mailAdminBought = if @"mailAdminBought" == "on": "true" else: "false"

    exec(db, sql("UPDATE basket_settings SET receipt_nr_next = ?, companyName = ?, companyDescription = ?, paymentMethod = ?, conditions = ?, mailOrder = ?, mailShipped = ?, mailAdminBought = ?, countries = ?"), @"receipt_nr_next", @"companyName", @"companyDescription", @"paymentMethod", @"conditions", mailOrder, mailShipped, mailAdminBought, @"countries")

    redirect("/basket/company/edit")

  # Edit translation
  get "/basket/translations/edit":
    createTFD()
    if not c.loggedIn or c.rank notin [Admin, Moderator]:
      redirect("/")

    resp genMain(c, genBasketTranslations(db))

  # Edit translation
  post "/basket/translations/edit":
    createTFD()
    if not c.loggedIn or c.rank notin [Admin, Moderator]:
      redirect("/")

    exec(db, sql("UPDATE basket_settings SET language = ?, languages = ?, translation = ?"), @"language", @"languages", @"translation")

    # Update translations
    langTable = basketLangGen(db)

    # Write JS file
    writeFile("public/js/basket_ui_" & basketV & ".js", @"jstranslation")

    redirect("/basket/translations/edit")

  # Restore JS file
  get "/basket/translations/jsrestore":
    createTFD()
    if not c.loggedIn or c.rank notin [Admin, Moderator]:
      redirect("/")

    copyFile(getAppDir().replace("nimwcpkg") / "plugins/basket/public/basket_ui.js", "public/js/basket_ui_" & basketV & ".js")

    redirect("/basket/translations/edit")



  #[
    Settings admin: Products
  ]#
  # Product page
  get "/basket/products/edit":
    createTFD()
    if not c.loggedIn or c.rank notin [Admin, Moderator]:
      redirect("/")

    resp genMain(c, genBasketProductEdit(db))

  # Add product
  post "/basket/products/add":
    createTFD()
    if not c.loggedIn or c.rank notin [Admin, Moderator]:
      redirect("/")

    if getValue(db, sql("SELECT identifier FROM basket_products WHERE identifier = ?"), @"identifer") != "":
      resp("Identifier already exists")

    if not isDigit(@"price") and @"price" != "":
      resp("Price needs to be a number")

    if not isDigit(@"vat") and @"vat" != "":
      resp("VAT needs to be a number")

    if @"quantity" == "":
      let id = tryInsertId(db, sql("INSERT INTO basket_products (identifier, productName, productDescription, price, vat, valuta, active, weight) VALUES (?, ?, ?, ?, ?, ?, ?, ?)"), @"identifier", @"name", @"description", @"price", @"vat", @"valuta", @"active", @"weight")
    else:
      let id = tryInsertId(db, sql("INSERT INTO basket_products (identifier, productName, productDescription, price, vat, valuta, active, weight, quantity) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)"), @"identifier", @"name", @"description", @"price", @"vat", @"valuta", @"active", @"weight", @"quantity")

    redirect("/basket/products/edit")

  # Edit product settings
  post "/basket/products/edit":
    createTFD()
    if not c.loggedIn or c.rank notin [Admin, Moderator]:
      redirect("/")

    if getValue(db, sql("SELECT identifier FROM basket_products WHERE identifier = ? AND id IS NOT ?"), @"identifer", @"id") != "":
      resp("Identifier already exists")

    if @"quantity" == "":
      exec(db, sql("UPDATE basket_products SET identifier = ?, productName = ?, productDescription = ?, price = ?, vat = ?, valuta = ?, active = ?, weight = ?, quantity = NULL WHERE id = ?;"), @"identifier", @"name", @"description", @"price", @"vat", @"valuta", @"active", @"weight", @"id")
    else:
      exec(db, sql("UPDATE basket_products SET identifier = ?, productName = ?, productDescription = ?, price = ?, vat = ?, valuta = ?, active = ?, weight = ?, quantity = ? WHERE id = ?;"), @"identifier", @"name", @"description", @"price", @"vat", @"valuta", @"active", @"weight", @"quantity", @"id")

    redirect("/basket/products/edit")

  # Delete product
  get "/basket/products/delete/@productID":
    createTFD()
    if not c.loggedIn or c.rank notin [Admin, Moderator]:
      redirect("/")

    exec(db, sql("DELETE FROM basket_products WHERE id = ?"), @"productID")

    resp genMain(c, genBasketProductEdit(db))



  #[
    Settings admin: Products
  ]#
  # Product page
  get "/basket/shipping/edit":
    createTFD()
    if not c.loggedIn or c.rank notin [Admin, Moderator]:
      redirect("/")

    resp genMain(c, genBasketShippingEdit(db))

  # Add product
  post "/basket/shipping/add":
    createTFD()
    if not c.loggedIn or c.rank notin [Admin, Moderator]:
      redirect("/")

    if not isDigit(@"price") and @"price" != "":
      resp("Price needs to be a number")

    if not isDigit(@"vat") and @"vat" != "":
      resp("VAT needs to be a number")

    let id = tryInsertId(db, sql("INSERT INTO basket_shipping (name, description, price, vat, valuta, minItems, maxItems, minWeight, maxWeight) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)"), @"name", @"description", @"price", @"vat", @"valuta", @"minitems", @"maxitems", @"minweight", @"maxweight")

    redirect("/basket/shipping/edit")

  # Edit shipping settings
  post "/basket/shipping/edit":
    createTFD()
    if not c.loggedIn or c.rank notin [Admin, Moderator]:
      redirect("/")

    exec(db, sql("UPDATE basket_shipping SET name = ?, description = ?, price = ?, vat = ?, valuta = ?, minItems = ?, maxItems = ?, minWeight = ?, maxWeight = ? WHERE id = ?;"), @"name", @"description", @"price", @"vat", @"valuta", @"minitems", @"maxitems", @"minweight", @"maxweight", @"id")

    redirect("/basket/shipping/edit")

  # Delete shipping
  get "/basket/shipping/delete/@shippingID":
    createTFD()
    if not c.loggedIn or c.rank notin [Admin, Moderator]:
      redirect("/")

    exec(db, sql("DELETE FROM basket_shipping WHERE id = ?"), @"shippingID")

    resp genMain(c, genBasketShippingEdit(db))





  #[
    Settings admin: PDF receipts
  ]#
  # Access all receipts pdf
  get "/basket/allreceiptspdf":
    createTFD()

    if not c.loggedIn or c.rank notin [Admin, Moderator]:
      redirect("/")

    resp genMain(c, genBuyAllReceiptsPdf(db))

  # Download receipt
  get "/basket/getreceiptpdf/@filename":
    createTFD()

    if not c.loggedIn or c.rank notin [Admin, Moderator]:
      redirect("/")

    sendFile(storageEFS / "receipts" / @"filename")




  #[
    Accounting: Setting purchase status
  ]#
  # Access all receipts
  get "/basket/allreceipts":
    createTFD()

    if not c.loggedIn or c.rank notin [Admin, Moderator]:
      redirect("/")

    resp genMain(c, genBuyAllReceipts(db))

  # Edit receipt status
  post "/basket/receipt/status/@action":
    createTFD()
    if not c.loggedIn or c.rank notin [Admin, Moderator]:
      redirect("/")

    case @"action"
    of "shipped":
      exec(db, sql("UPDATE basket_purchase SET shipped = ?, modified = ? WHERE id = ?"), "true", toInt(epochTime()), @"purchase_id")

      if getValue(db, sql("SELECT mailShipped FROM basket_settings")) == "true":
        let userData = getRow(db, sql("SELECT name, email FROM basket_purchase WHERE id = ?"), @"purchase_id")

        let
          appDir       = getAppDir().replace("nimwcpkg", "")
          dict         = loadConfig(appDir / "config/config.cfg")
          supportEmail = dict.getSectionValue("SMTP", "SMTPEmailSupport")
          mailSubject  = basketLang("mailSubjectShipped")
          mailMsg      = basketLang("mailMsgShipped")
          webUrl       = dict.getSectionValue("Server", "website")

        # TODO https://github.com/ThomasTJdev/nim_websitecreator/issues/127
        let userTitle = dict.getSectionValue("Server", "title")

        asyncCheck sendMailNow(
                  mailSubject.format(userTitle),
                  mailMsg.format(userData[0], webUrl & "/basket/pdfreceipt/login",
                  supportEmail, userTitle), userData[1].toLowerAscii())

    of "notshipped":
      exec(db, sql("UPDATE basket_purchase SET shipped = ?, modified = ? WHERE id = ?"), "false", toInt(epochTime()), @"purchase_id")
    else:
      #[
        payment_received:
          payed
          awaiting
          notchecked
          cancelled
      ]#
      exec(db, sql("UPDATE basket_purchase SET payment_received = ?, modified = ? WHERE id = ?"), @"action", toInt(epochTime()), @"purchase_id")

      # If cancelled, reinsert items in stock (quantity)
      if @"action" == "cancelled":
        let soldQuantity = getAllRows(db, sql("SELECT productcount, product_id FROM basket_purchase_products WHERE purchase_id = ?"), @"purchase_id")
        for soldQ in soldQuantity:
          #try:
          let soldCount = parseInt(soldQ[0])
          let productID = soldQ[1]

          let currQuantityTmp = getValue(db, sql("SELECT quantity FROM basket_products WHERE id = ?"), productID)
          if currQuantityTmp != "":
            let currQuantity = parseInt(currQuantityTmp)

            let newQuantity = soldCount + currQuantity

            exec(db, sql("UPDATE basket_products SET quantity = ? WHERE id = ?"), newQuantity, productID)
            #except:
            #  resp("Der skete en fejl. Kontakt venligst support.")


    redirect("/basket/allreceipts")




  #[
    Customer routes
  ]#
  # Access the buy now page
  get "/basket/products":
    createTFD()

    resp genMain(c, genBaskerProductoverview(db, c.loggedIn))


  # Access the buy now page
  get "/basket/buynow/@identifier":
    createTFD()

    if c.loggedIn and @"identifier" == "multiple":
      resp genMain(c, genBuyNow(db, c.loggedIn, @"products", singleProduct=false))

    else:
      let active = if c.loggedIn: "" else: " AND (active IS NULL or active = '1')"
      if getValue(db, sql("SELECT id FROM basket_products WHERE identifier = ?" & active), @"identifier") == "":
        redirect("/")

    resp genMain(c, genBuyNow(db, c.loggedIn, @"identifier"))

  # Make the buy
  post "/basket/buynow":
    createTFD()

    when not defined(dev):
      when defined(recaptcha):
        if useCaptcha:
          let isRecaptchaOk = not(await checkReCaptcha(@"grecaptcharesponse", c.req.ip))

          if isRecaptchaOk:
            redirect("/")

    let isPrivate = if c.loggedIn: true else: false

    # Check params
    if @"email".len() == 0 or "@" notin @"email" or "." notin @"email":
      resp(basketLang("errorEmail"))
    let email = @"email".toLowerAscii()

    if @"password".len() < 4:
      resp(basketLang("errorPwd"))
    let passwordRaw = @"password".strip

    if @"address".len() < 4:
      resp(basketLang("errorAddress"))

    if @"city".len() == 0:
      resp(basketLang("errorCity"))

    if @"productcount" == "": # or parseInt(@"productcount") > 10:
      resp(basketLang("errorQuantity"))

    let
      # Password
      salt = makeSalt()
      password = makePassword(passwordRaw, salt)
      receipt_nr_next = getValue(db, sql("SELECT receipt_nr_next FROM basket_settings"))

    var shippingData: Row
    if @"shipping" != "":
      shippingData = getRow(db, sql("SELECT price, vat FROM basket_shipping WHERE id = ?"), @"shipping")
      if shippingData.len() == 0:
        resp(basketLang("errorShippingExist"))


    # Update next receipt number, and use current receipt number
    let receipt_nr = if receipt_nr_next == "": "1" else: receipt_nr_next
    let receipt_nr_next_inc = if receipt_nr == "": "2" else: $(parseInt(receipt_nr) + 1)
    exec(db, sql("UPDATE basket_settings SET receipt_nr_next = ?"), receipt_nr_next_inc)

    # Create purchase data
    let purchaseID = insertID(db, sql("INSERT INTO basket_purchase (email, salt, password, name, company, companyid, address, phone, city, zip, country, shipping, shippingDetails, shippingPrice, shippingVat, payment_received, receipt_nr) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)"), email, salt, password, @"name", @"company", @"companyid", @"address", @"phone", @"city", @"zip", @"country", @"shipping", @"shippingDetails", shippingData[0], shippingData[1], "notchecked", $receipt_nr)

    if purchaseID == -1 or purchaseID == 0:
      resp(basketLang("error"))


    # Create purchase items
    var
      exist: bool
      count: int
    let
      active = if c.loggedIn == true: "" else: " AND active = '1'"  # If user is logged in, allow access to not active products
      productCount = split(@"productcount", ",")

    # Loop through each product
    for productID in split(@"id", ","):
      let productData = getRow(db, sql("SELECT price, vat, valuta, productName FROM basket_products WHERE id = ?" & active), productID)

      if productData.len() == 0:
        continue

      # Check if item is in stock. If not, cancel buy.
      let currentQuantityTmp = getValue(db, sql("SELECT quantity FROM basket_products WHERE id = ?"), productID)
      var currentQuantity: int
      if currentQuantityTmp != "":
        #try:
        currentQuantity = parseInt(currentQuantityTmp)
        let newQuantity = currentQuantity - parseInt(productCount[count])

        # If its out of stock
        if newQuantity < 0:
          exec(db, sql("DELETE FROM basket_purchase_products WHERE purchase_id = ?"), purchaseID)
          exec(db, sql("UPDATE basket_purchase SET payment_received = ? WHERE id = ?"), "cancelled", purchaseID)
          resp(basketLang("errorNotInStock1") & " " & productData[3] & basketLang("errorNotInStock2"))

        # Set new quantity
        exec(db, sql("UPDATE basket_products SET quantity = ? WHERE id = ?"), newQuantity, productID)

        #except:
        #resp("Der skete en fejl. Kontakt venligst support.")

      exec(db, sql("INSERT INTO basket_purchase_products (purchase_id, product_id, price, vat, valuta, productcount) VALUES (?, ?, ?, ?, ?, ?)"), purchaseID, productID, productData[0], productData[1], productData[2], productCount[count])


      exist = true
      count      += 1

    if not exist:
      redirect("/")


    # PDF receipt
    let
      filename = $purchaseID & "_" & email.multiReplace([("@", "_"), (".", "_")]) & ".pdf"
      filepath = storageEFS / "receipts" / filename
      cusmsg = if c.loggedIn: @"cusmsg" else: ""

    pdfBuyGenerator(db, $purchaseID, filepath, email, @"multi", cusmsg)


    # Receipt mail
    let receipts = getAllRows(db, sql("SELECT id, email, receipt_nr, creation, password, salt, payment_received, shipped FROM basket_purchase WHERE email = ?"), email)

    let payment = getValue(db, sql("SELECT paymentMethod FROM basket_settings;")).replace("\n", "<br>")

    var
      tmpValuta: string
      receiptValuta: string
      receiptTotalprice: float
      receiptProductname: string

    let
      allProduct = getAllRows(db, sql("SELECT bpp.valuta, bpp.price, bpp.vat, bpp.productCount, bp.productName FROM basket_purchase_products AS bpp LEFT JOIN basket_products AS bp ON bp.id = bpp.product_id WHERE bpp.purchase_id = ?"), purchaseID)

    # Get product data (valuta and pricing)
    for product in allProduct:
      receiptValuta = product[0]
      receiptTotalprice += (parseFloat(product[1]) + parseFloat(product[2])) * parseFloat(product[3])
      if receiptProductname != "":
        receiptProductname.add(", ")
      receiptProductname.add(product[4])

    # Final price - products + shipping
    receiptTotalprice += parseFloat(shippingData[0]) + parseFloat(shippingData[1])


    if @"sendmail" == "true" and getValue(db, sql("SELECT mailOrder FROM basket_settings;")) == "true":
      let
        appDir       = getAppDir().replace("nimwcpkg", "")
        dict         = loadConfig(appDir / "config/config.cfg")
        supportEmail = dict.getSectionValue("SMTP", "SMTPEmailSupport")
        mailSubject  = basketLang("mailSubjectCongrats")
        mailMsg      = basketLang("mailMsgCongrats")
        webUrl       = dict.getSectionValue("Server", "website")

      # TODO https://github.com/ThomasTJdev/nim_websitecreator/issues/127
      let userTitle = dict.getSectionValue("Server", "title")

      asyncCheck sendBasketReceipt(email,
                    mailSubject.format(userTitle, receiptProductname),
                    mailMsg.format(@"name",
                        receiptProductname,
                        $receiptTotalprice & " " & receiptValuta,
                        payment,
                        webUrl & "/basket/pdfreceipt/login",
                        supportEmail,
                        userTitle,
                        receipt_nr),
                    filepath,
                    $receipt_nr)

    if getValue(db, sql("SELECT mailAdminBought FROM basket_settings;")) == "true":
      # TODO https://github.com/ThomasTJdev/nim_websitecreator/issues/127
      let userTitle = dict.getSectionValue("Server", "title")
      let adminMessage = """There's a new buyer!<br><br>$1 has bought $2 for $3.""" % [@"name", receiptProductname, $receiptTotalprice & " " & receiptValuta]
      asyncCheck sendAdminMailNow(userTitle & ": New buyer", adminMessage)

    resp genBuyShowPdf(db, email, @"password", receipts)



  #[
    Customer: Access receipts
  ]#
  # Login to access receipts
  get "/basket/pdfreceipt/login":
    createTFD()

    resp genMain(c, genBuyReceiptPdf(db))

  # Access all receipts
  post "/basket/pdfreceipt":
    createTFD()

    let email = @"email".toLowerAscii()
    let password = @"password".strip()

    let receipts = getAllRows(db, sql("SELECT id, email, receipt_nr, creation, password, salt, payment_received, shipped FROM basket_purchase WHERE email = ?"), email)

    if receipts.len() == 0:
      redirect("/basket/pdfreceipt/login")

    var hasReceipts = false
    for receipt in receipts:
      if receipt[4] == makePassword(password, receipt[5], receipt[4]):
        hasReceipts = true
        break

    if not hasReceipts:
      redirect("/basket/pdfreceipt/login")

    resp genMain(c, genBuyShowPdf(db, email, password, receipts))

  # Download PDF receipt
  post "/basket/pdfreceipt/download/@filename":
    createTFD()

    let email = @"email".toLowerAscii()
    let password = @"password".strip()

    let data = getRow(db, sql("SELECT id, email, password, salt FROM basket_purchase WHERE id = ? AND email = ?"), @"id", email)

    if data.len() == 0:
      redirect("/")

    if data[2] != makePassword(password, data[3], data[2]):
      redirect("/")

    let path = storageEFS / "receipts" / @"filename"
    if fileExists(path):
      sendFile(path)

    redirect("/")


  # Conditions
  get "/basket/conditions":
    createTFD()

    resp genMain(c, genBasketConditions(db))