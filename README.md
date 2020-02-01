# Nim Website Creator - Basket
[Nim Website Creator](https://github.com/ThomasTJdev/nim_websitecreator) plugin to enable an ecommerce webshop, where user can buy products and get a receipt.

## Requirement
This is a plugin for [Nim Website Creator](https://github.com/ThomasTJdev/nim_websitecreator) and can not be compiled individually.

### Dependencies

* [nimPdf](https://github.com/jangko/nimpdf) - `nimble install nimpdf`
* [mime](https://github.com/enthus1ast/nimMime) - Clone the repo and run `nimble install`


## Changelog
### v0.5
* Create receipts for private products

```sql
ALTER TABLE basket_purchase ADD COLUMN multiple_product_count VARCHAR(100);
```


### v0.4
* Remove cutoff of description of products and shipping.
* Send an email to the admin, when product is bought (activate in settings)
```
ALTER TABLE basket_settings ADD COLUMN mailAdminBought VARCHAR(10);
```
* Deactivate/activate a product
```
ALTER TABLE basket_products ADD COLUMN active INTEGER;
```
* New DB column to store custom shipping details (disabled by default in css `.wipshippingdetails`)
```
ALTER TABLE basket_purchase ADD COLUMN shippingDetails VARCHAR(1000);
```

### v0.3
* Minor design
* Full JS translation
* Setting page for translations

### v0.2
* New DB columns:
```
ALTER TABLE basket_settings ADD COLUMN languages TEXT;
ALTER TABLE basket_settings ADD COLUMN language VARCHAR(10);
ALTER TABLE basket_settings ADD COLUMN translation TEXT;
```
* Support for translations

## Features

### Admin

* Create multiple products with specific prices and vats
* Create multiple shipping options
* Keep track and update status on payments, awaiting payments, shipped orders etc. (manually)
* Set company data in one place
* Enable mails to customer on order and shipping
* Make a buying conditions page
* Full translation - use your own language, customize all language variables from the browser

### Customer

* Buy products with an online form. Choose number of products and shipping method.
* Make profile where all receipts can be accessed
* Download PDF receipts
* Access old receipts
* Receive mail on placing order and when order is shipped

## Start

1) Open the main settings and specify your company data
2) Add a product
3) Add a shipping method
4) Launch

If you prefer another language than Danish or English:
1) Add you language in the language settings
2) Edit the JS file to include your language
3) Make a PR or issue containing your language, so the repo can be updated :)

## Use

* Plugin settings `/basket/settings`
* Access all the products on `/basket/products`
* Buy a single product with `/basket/products/@identifier`. You can design your own product page, and just insert links to the products.

## Todo

* Let user add multiple products to basket.
* Clear up proc names - it's mixed with buy and basket.

# Screenshots

**Stats**

![stats](screenshots/stats.png)

___

**Products**

![products](screenshots/products.png)

___

**Shipping**

![shipping](screenshots/shipping.png)

___

**Accounting 1**

![accounting1](screenshots/accounting1.png)

___

**Accounting 2**

![accounting2](screenshots/accounting2.png)