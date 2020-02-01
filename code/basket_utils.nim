# Copyright 2020 - Thomas T. Jarløv

import datetime2human, strutils, db_sqlite
import translation

proc getProductData*(db: DbConn, identifier: string, singleProduct, loggedIn: bool): seq[Row] =
  ## Get product data

  let isActive = if loggedIn: "" else: " AND active = '1'"

  if singleProduct:
    return getAllRows(db, sql("SELECT id, price, vat, valuta, productName, productDescription FROM basket_products WHERE identifier = ?" & isActive), identifier)

  else:
    try:
      return getAllRows(db, sql("SELECT id, price, vat, valuta, productName, productDescription FROM basket_products WHERE id in (" & identifier.multiReplace([("\'", ""), ("\"", "")]) & ")" & isActive))
    except:
      return @[]


proc getProductPrice*(db: DbConn, identifier: string, singleProduct, loggedIn: bool): Row =
  ## Get product data

  let isActive = if loggedIn: "" else: " AND active = '1'"

  if singleProduct:
    return getRow(db, sql("SELECT price, vat FROM basket_products WHERE identifier = ?" & isActive), identifier)

  else:
    let data = getAllRows(db, sql("SELECT price, vat FROM basket_products WHERE identifier in (?)" & isActive), identifier)

    var
      price: int
      vat: int

    for d in data:
      price += parseInt(d[0])
      vat += parseInt(d[1])

    return @[$price, $vat]