
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
  # Edit settings page
  get "/basket/settings/edit":
    createTFD()
    if not c.loggedIn or c.rank notin [Admin, Moderator]:
      redirect("/")

    resp genMain(c, genBuyEditsettings(db))

  # Edit main settings
  post "/basket/editsettings/main":
    createTFD()
    if not c.loggedIn or c.rank notin [Admin, Moderator]:
      redirect("/")

    #exec(db, sql("UPDATE basket_settings SET receipt_nr_next = ?, productName = ?, productDescription = ?, companyName = ?, companyDescription = ?, paymentMethod = ?"), @"receipt_nr_next", @"productName", @"productDescription", @"companyName", @"companyDescription", @"paymentMethod")

    let mailOrder = if @"mailOrder" == "on": "true" else: "false"
    let mailShipped = if @"mailShipped" == "on": "true" else: "false"

    exec(db, sql("UPDATE basket_settings SET receipt_nr_next = ?, companyName = ?, companyDescription = ?, paymentMethod = ?, conditions = ?, mailOrder = ?, mailShipped = ?, countries = ?, language = ?, languages = ?, translation = ?"), @"receipt_nr_next", @"companyName", @"companyDescription", @"paymentMethod", @"conditions", mailOrder, mailShipped, @"countries", @"language", @"languages", @"translation")

    langTable = basketLangGen(db)

    redirect("/basket/settings/edit")



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

    let id = tryInsertId(db, sql("INSERT INTO basket_products (identifier, productName, productDescription, price, vat, valuta) VALUES (?, ?, ?, ?, ?, ?)"), @"identifier", @"name", @"description", @"price", @"vat", @"valuta")

    redirect("/basket/products/edit")

  # Edit price settings
  post "/basket/products/edit":
    createTFD()
    if not c.loggedIn or c.rank notin [Admin, Moderator]:
      redirect("/")

    if getValue(db, sql("SELECT identifier FROM basket_products WHERE identifier = ? AND id IS NOT ?"), @"identifer", @"id") != "":
      resp("Identifier already exists")

    exec(db, sql("UPDATE basket_products SET identifier = ?, productName = ?, productDescription = ?, price = ?, vat = ?, valuta = ? WHERE id = ?;"), @"identifier", @"name", @"description", @"price", @"vat", @"valuta", @"id")

    redirect("/basket/products/edit")

  #[ Edit price settings
  post "/basket/editsettings/product":
    createTFD()
    if not c.loggedIn or c.rank notin [Admin, Moderator]:
      redirect("/")

    exec(db, sql("UPDATE basket_products SET identifier = ?, price = ?, vat = ?, valuta = ?"), @"identifier", @"price", @"vat", @"valute")

    redirect("/basket/settings/edit")
  ]#



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

    resp genMain(c, genBaskerProductoverview(db))


  # Access the buy now page
  get "/basket/buynow/@identifier":
    createTFD()

    if getValue(db, sql("SELECT id FROM basket_products WHERE identifier = ?"), @"identifier") == "":
      redirect("/")

    resp genMain(c, genBuyNow(db, @"identifier"))

  # Make the buy
  post "/basket/buynow":
    createTFD()

    when not defined(dev):
      when defined(recaptcha):
        if useCaptcha:
          let isRecaptchaOk = not(await checkReCaptcha(@"grecaptcharesponse", c.req.ip))

          if isRecaptchaOk:
            redirect("/")

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

    if @"productcount" == "" or parseInt(@"productcount") > 10:
      resp("Ønsker du at bestille mere end 10 bøger, skal du skrive en mail for rabat.")

    let
      # Password
      salt = makeSalt()
      password = makePassword(passwordRaw, salt)

      # Receipt info
      productData = getRow(db, sql("SELECT price, vat, valuta, productName FROM basket_products WHERE id = ?"), @"id")
      receipt_nr_next = getValue(db, sql("SELECT receipt_nr_next FROM basket_settings"))
      shippingData = getRow(db, sql("SELECT price, vat FROM basket_shipping WHERE id = ?"), @"shipping")

    # Update next receipt number, and use current receipt number
    let receipt_nr = if receipt_nr_next == "": "1" else: receipt_nr_next
    let receipt_nr_next_inc = if receipt_nr == "": "2" else: $(parseInt(receipt_nr) + 1)
    exec(db, sql("UPDATE basket_settings SET receipt_nr_next = ?"), receipt_nr_next_inc)

    # Create purchase data
    # Single product, otherwise "multiple_product_id"
    let id = insertID(db, sql("INSERT INTO basket_purchase (product_id, price, vat, valuta, productcount, email, salt, password, name, company, address, phone, city, zip, country, shipping, payment_received, receipt_nr) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)"), @"id", productData[0], productData[1], productData[2], @"productcount", email, salt, password, @"name", @"company", @"address", @"phone", @"city", @"zip", @"country", @"shipping", "notchecked", $receipt_nr)
    if id == -1: # or id.len() == 0:
      resp("Der skete en fejl.")

    # CREATE PDF
    let filename = $id & "_" & email.multiReplace([("@", "_"), (".", "_")]) & ".pdf"
    let filepath = storageEFS / "receipts" / filename

    pdfBuyGenerator(db, $id, filepath, email)

    let receipts = getAllRows(db, sql("SELECT id, productcount, receipt_nr, creation, password, salt, payment_received, shipped FROM basket_purchase WHERE email = ?"), email)

    let productPrice = (parseInt(productData[0]) + parseInt(productData[1])) * parseInt(@"productcount")
    let shippingPrice = parseInt(shippingData[0]) + parseInt(shippingData[1])
    let totalPrice = productPrice + shippingPrice

    let payment = getValue(db, sql("SELECT paymentMethod FROM basket_settings;")).replace("\n", "<br>")

    if getValue(db, sql("SELECT mailOrder FROM basket_settings;")) == "true":
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
                        $totalPrice & " " & productData[2],
                        payment,
                        mainURL & "/basket/pdfreceipt/login",
                        supportEmail,
                        title,
                        receipt_nr),
                    filepath,
                    $receipt_nr)

      #asyncCheck sendMailNow(
      #          mailSubjectCongrats.format(title, productData[3]),
      #          mailMsgCongrats.format(@"name", productData[3], $totalPrice & " " & productData[2], payment, mainURL & "/basket/pdfreceipt/login", supportEmail, title, receipt_nr),
      #          @"email")

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

    # storageEFS / "receipts" / (@"email".multiReplace([("@", "_"), (".", "_")]) & ".pdf")
    let path = storageEFS / "receipts" / @"filename"
    if fileExists(path):
      sendFile(path)

    redirect("/")


  # Conditions
  get "/basket/conditions":
    createTFD()

    resp genMain(c, genBasketConditions(db))


  # Fake generation of receipt in dev-mode
  get "/basket/fake":
    createTFD()

    when defined(dev):
      pdfBuyGenerator(db, "15", storageEFS, "niss@ttj.dk")

      resp("OK")

    else:
      redirect("/")

