
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

    let id = tryInsertId(db, sql("INSERT INTO basket_products (identifier, productName, productDescription, price, vat, valuta, active) VALUES (?, ?, ?, ?, ?, ?, ?)"), @"identifier", @"name", @"description", @"price", @"vat", @"valuta", @"active")

    redirect("/basket/products/edit")

  # Edit price settings
  post "/basket/products/edit":
    createTFD()
    if not c.loggedIn or c.rank notin [Admin, Moderator]:
      redirect("/")

    if getValue(db, sql("SELECT identifier FROM basket_products WHERE identifier = ? AND id IS NOT ?"), @"identifer", @"id") != "":
      resp("Identifier already exists")

    exec(db, sql("UPDATE basket_products SET identifier = ?, productName = ?, productDescription = ?, price = ?, vat = ?, valuta = ?, active = ? WHERE id = ?;"), @"identifier", @"name", @"description", @"price", @"vat", @"valuta", @"active", @"id")

    redirect("/basket/products/edit")



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

    let id = tryInsertId(db, sql("INSERT INTO basket_shipping (name, description, price, vat, valuta) VALUES (?, ?, ?, ?, ?)"), @"name", @"description", @"price", @"vat", @"valuta")

    redirect("/basket/shipping/edit")

  # Edit price settings
  post "/basket/shipping/edit":
    createTFD()
    if not c.loggedIn or c.rank notin [Admin, Moderator]:
      redirect("/")

    exec(db, sql("UPDATE basket_shipping SET name = ?, description = ?, price = ?, vat = ?, valuta = ? WHERE id = ?;"), @"name", @"description", @"price", @"vat", @"valuta", @"id")

    redirect("/basket/shipping/edit")





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
      exec(db, sql("UPDATE basket_purchase SET shipped = ?, modified = ? WHERE id = ?"), "true", toInt(epochTime()), @"receipt_id")

      if getValue(db, sql("SELECT mailShipped FROM basket_settings;")) == "true":
        let userData = getRow(db, sql("SELECT name, email FROM basket_purchase WHERE id = ?"), @"receipt_id")

        let
          appDir       = getAppDir().replace("nimwcpkg", "")
          dict         = loadConfig(appDir / "config/config.cfg")
          supportEmail = dict.getSectionValue("SMTP", "SMTPEmailSupport")
          mailSubject  = basketLang("mailSubjectShipped")
          mailMsg      = basketLang("mailMsgShipped")

        asyncCheck sendMailNow(
                  mailSubject.format(title),
                  mailMsg.format(@"name", mainURL & "/basket/pdfreceipt/login",
                  supportEmail, title), @"email".toLowerAscii())

    of "notshipped":
      exec(db, sql("UPDATE basket_purchase SET shipped = ?, modified = ? WHERE id = ?"), "false", toInt(epochTime()), @"receipt_id")
    else:
      exec(db, sql("UPDATE basket_purchase SET payment_received = ?, modified = ? WHERE id = ?"), @"action", toInt(epochTime()), @"receipt_id")

    redirect("/basket/settings")




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
      resp("Fejl, email formatet er forkert")
    let email = @"email".toLowerAscii()

    if @"password".len() < 4:
      resp("Fejl, dit password er for kort.")
    let passwordRaw = @"password".strip

    if @"address".len() < 4:
      resp("Fejl, din adresse er for kort.")

    if @"city".len() == 0:
      resp("Fejl, du mangler at angive din by.")

    if @"productcount" == "": # or parseInt(@"productcount") > 10:
      resp("Ønsker du at bestille mere end 10 bøger, skal du skrive en mail for rabat.")

    let
      # Password
      salt = makeSalt()
      password = makePassword(passwordRaw, salt)
      receipt_nr_next = getValue(db, sql("SELECT receipt_nr_next FROM basket_settings"))
      
    var shippingData: Row
    if @"shipping" != "":
      shippingData = getRow(db, sql("SELECT price, vat FROM basket_shipping WHERE id = ?"), @"shipping")

    # Receipt info
    var
      productData: Row
      totalPrice: int
      totalVat: int
      totalPriceWithShipping: int
      count: int
      exist: bool

    let
      active = if c.loggedIn == true: "" else: " AND active = '1'"
      productCount = split(@"productcount", ",")

    if @"multi" == "true":
      for productId in split(@"id", ","):
        productData = getRow(db, sql("SELECT price, vat, valuta, productName FROM basket_products WHERE id = ?" & active), productId)
        if productData.len() > 0:
          exist = true

        totalPrice += parseInt(productData[0]) * parseInt(productCount[count])
        totalVat   += parseInt(productData[1]) * parseInt(productCount[count])
        count      += 1

      if not exist:
        redirect("/")

      if shippingData.len() > 0:
        totalPriceWithShipping = totalPrice + totalVat + parseInt(shippingData[0]) + parseInt(shippingData[1])
      else:
        totalPriceWithShipping = totalPrice + totalVat

    else:
      productData = getRow(db, sql("SELECT price, vat, valuta, productName FROM basket_products WHERE id = ?" & active), @"id")
      if productData.len() == 0:
        redirect("/")

      let productPrice = (parseInt(productData[0]) + parseInt(productData[1])) * parseInt(@"productcount")
      
      if shippingData.len() > 0:
        let shippingPrice = parseInt(shippingData[0]) + parseInt(shippingData[1])
        totalPriceWithShipping = productPrice + shippingPrice
      else:
        totalPriceWithShipping = productPrice

    # Update next receipt number, and use current receipt number
    let receipt_nr = if receipt_nr_next == "": "1" else: receipt_nr_next
    let receipt_nr_next_inc = if receipt_nr == "": "2" else: $(parseInt(receipt_nr) + 1)
    exec(db, sql("UPDATE basket_settings SET receipt_nr_next = ?"), receipt_nr_next_inc)

    # Create purchase data
    # Single product, otherwise "multiple_product_id"
    var id: int64
    if @"multi" == "true":
      id = insertID(db, sql("INSERT INTO basket_purchase (multiple_product_id, price, vat, valuta, multiple_product_count, email, salt, password, name, company, address, phone, city, zip, country, shipping, shippingDetails, payment_received, receipt_nr) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)"), @"id", $totalPrice, $totalVat, "", @"productcount", email, salt, password, @"name", @"company", @"address", @"phone", @"city", @"zip", @"country", @"shipping", @"shippingDetails", "notchecked", $receipt_nr)
      
    else:
      id = insertID(db, sql("INSERT INTO basket_purchase (product_id, price, vat, valuta, productcount, email, salt, password, name, company, address, phone, city, zip, country, shipping, shippingDetails, payment_received, receipt_nr) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)"), @"id", productData[0], productData[1], productData[2], @"productcount", email, salt, password, @"name", @"company", @"address", @"phone", @"city", @"zip", @"country", @"shipping", @"shippingDetails", "notchecked", $receipt_nr)
    
    if id == -1 or id == 0:
      resp("Der skete en fejl.")

    # CREATE PDF
    let filename = $id & "_" & email.multiReplace([("@", "_"), (".", "_")]) & ".pdf"
    let filepath = storageEFS / "receipts" / filename

    let cusmsg = if c.loggedIn: @"cusmsg" else: ""
    pdfBuyGenerator(db, $id, filepath, email, @"multi", cusmsg)

    let receipts = getAllRows(db, sql("SELECT id, productcount, receipt_nr, creation, password, salt, payment_received, shipped FROM basket_purchase WHERE email = ?"), email)

    let payment = getValue(db, sql("SELECT paymentMethod FROM basket_settings;")).replace("\n", "<br>")

    
    if @"sendmail" == "true" and getValue(db, sql("SELECT mailOrder FROM basket_settings;")) == "true":
      let
        appDir       = getAppDir().replace("nimwcpkg", "")
        dict         = loadConfig(appDir / "config/config.cfg")
        supportEmail = dict.getSectionValue("SMTP", "SMTPEmailSupport")
        mailSubject  = basketLang("mailSubjectCongrats")
        mailMsg      = basketLang("mailMsgCongrats")

      asyncCheck sendBasketReceipt(email,
                    mailSubject.format(title, productData[3]),
                    mailMsg.format(@"name",
                        productData[3],
                        $totalPriceWithShipping & " " & productData[2],
                        payment,
                        mainURL & "/basket/pdfreceipt/login",
                        supportEmail,
                        title,
                        receipt_nr),
                    filepath,
                    $receipt_nr)

    if getValue(db, sql("SELECT mailAdminBought FROM basket_settings;")) == "true":
      let adminMessage = """There's a new buyer!<br><br>$1 has bought $2 for $3.""" % [@"name", productData[3], $totalPriceWithShipping & " " & productData[2]]
      asyncCheck sendAdminMailNow("New buyer", adminMessage)

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

    let receipts = getAllRows(db, sql("SELECT id, productcount, receipt_nr, creation, password, salt, payment_received, shipped FROM basket_purchase WHERE email = ?"), email)

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
  post "/basket/pdfreceipt/download":
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