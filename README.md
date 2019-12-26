# Nim Website Creator - Basket
[Nim Website Creator](https://github.com/ThomasTJdev/nim_websitecreator) plugin to enable an ecommerce webshop, where user can buy products and get a receipt.

## Requirement
This is a plugin for [Nim Website Creator](https://github.com/ThomasTJdev/nim_websitecreator) and can not be compiled individually.

### Dependencies

* [nimPdf](https://github.com/jangko/nimpdf) - `nimble install nimpdf`
* [mime](https://github.com/ThomasTJdev/nimMime) - Clone the repo and run `nimble install`

## Warn
There's some strings in Danish. If you would like it your language, you have to edit the source code. PR's are welcome.

## Features

### Admin

* Create multiple products with specific prices and vats
* Create multiple shipping options
* Keep track and update status on payments, awaiting payments, shipped orders etc. (manually)
* Set company data in one place
* Enable mails to customer on order and shipping
* Make a buying conditions page

### Customer

* Buy product with en online form. Choose number of products and shipping method.
* Make profile where all receipts can be accessed
* Download PDF receipts
* Access old receipts
* Receive mail on placing order and when order is shipped

## Start

1) Open the main settings and specify your company data
2) Add a product
3) Add a shipping method
4) Launch

## Use

* Plugin settings `/basket/settings`
* Access all the products on `/basket/products`
* Buy a single product with `/basket/products/@identifier`. You can design your own product page, and just insert links to the products.

## Todo

* Let user add multiple products to basket.
* Make a generic translation.
* Clear up proc names - it's mixed with buy and basket.