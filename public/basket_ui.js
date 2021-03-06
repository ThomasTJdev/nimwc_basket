/*
  Basket: Customer
*/
// Translations
// Set lang
var lang = document.getElementById("userLang").value;
if (lang == "" || lang == undefined) {
  lang = "EN";
}
// Return translation
function langGen(text) {
  try {
    return window["lang" + text][lang];
  } catch (err) {
    console.log("Error: Translation of " + text + " failed. Err code: " + err);
    return ""
  }
}
// Translations
/*
  EDIT TRANSLATIONS
  Insert your language in the following variables.
*/
var langError = {
  EN: "Error",
  DK: "Fejl"
}
var langTryAgain = {
  EN: "Please try again",
  DK: "Prøv venligst igen"
}
var langErrorContact = {
  EN: "Error, something went wrong. Please contact the administrator.",
  DK: "Der er sket en fejl. Kontakt venligst administratoren."
}
var langStopQuantity = {
  EN: "Choose the quantity (number of goods).",
  DK: "Angiv venligst antallet af varer."
}
var langStopNotInStock = {
  EN: "That amount is not in stock. Max items are ",
  DK: "Det antal er ikke på lager. Maks antal er "
}
var langStopNoShipping = {
  EN: "There's no shipping method for this number of items.",
  DK: "Der er ingen forsendelsesmetode for det antal."
}
var langStopEmail = {
  EN: "Please write your email.",
  DK: "Skriv venligst din email."
}
var langStopName = {
  EN: "Please write your name.",
  DK: "Skriv venligst dit navn."
}
var langStopPass = {
  EN: "Please insert a password.",
  DK: "Angiv venligst et password."
}
var langStopAddress = {
  EN: "Please insert an address.",
  DK: "Angiv venligst en adresse."
}
var langStopCity = {
  EN: "Please insert a city.",
  DK: "Angiv venligst en by."
}
var langStopZip = {
  EN: "Please insert a zip code.",
  DK: "Angiv venligst et postnummer."
}
var langStopCountry = {
  EN: "Please choose a country.",
  DK: "Angiv venligst et lang."
}
var langChooseShip = {
  EN: "Please choose a shipping method.",
  DK: "Vælg venligst en forsendelsesmetode."
}
var langAcceptTerms = {
  EN: "Accept the terms and conditions.",
  DK: "Accepter venligst vilkårene nederst."
}
/*
  STOP TRANSLATIONS
  You have now reach the end of translations
*/


function parseFloatSafe(strRaw) {
  if (strRaw == "") {
    return parseFloat("0.0");
  }
  return parseFloat(strRaw); //.replace(/\./g, '').replace(',', '.'));
}



// Function to check if the return has encountered an error
var codeLangError = ["Error", "Fejl"];
function isError(response) {
  if (codeLangError.includes(response.split(',')[0])) {
    return true;
  } else if (codeLangError.includes(response.split(':')[0])) {
    return true;
  } else if (codeLangError.includes(response.split(' ')[0])) {
    return true;
  } else if (response.slice(0, 5) == "Error") {
    // To be deprecated
    return true
  }
}

function backToProduct() {
  document.getElementById("buyProduct").style.display = "block";
  document.getElementById("buyBuying").style.display = "none";
}
function gotoBuying() {
  var count = document.getElementsByClassName('productcount');
  for (var i = 0, length = count.length; i < length; i++) {
    var parNumber = count[i].value;
    if (parNumber == "") {
      infoModal(langGen("StopQuantity"));
      return false;
    }
    if (parNumber == "0") {
      infoModal(langGen("StopQuantity"));
      return false;
    }
  }

  var shipping = document.getElementsByClassName("shippingItem");
  var shippingNumber = shipping.length;
  var countShip = 0;

  var count = document.getElementsByClassName('productcount');
  var countItemInt = 0;
  var countWeightInt = 0;
  for (var d = 0, dlength = count.length; d < dlength; d++) {
    var countItem = count[d].value;
    var countWeight = count[d].getAttribute("data-weight");
    countItemInt += parseInt(countItem, 10);
    countWeightInt += countItemInt * parseInt(countWeight, 10);

    var countQuantity = count[d].getAttribute("data-quantity");
    if (countQuantity != "") {
      if (parseInt(countQuantity, 10) < parseInt(countItem, 10)) {
        infoModal(langGen("StopNotInStock") + countQuantity);
        return false;
      }
    }
  }

  for (var i = 0, length = shipping.length; i < length; i++) {
    var shipItemsMin = shipping[i].getAttribute("data-minitems");
    var shipItemsMinInt = parseInt(shipItemsMin, 10);
    var shipItemsMax = shipping[i].getAttribute("data-maxitems");
    var shipItemsMaxInt = parseInt(shipItemsMax, 10);

    var shipWeightMin = shipping[i].getAttribute("data-minweight");
    var shipWeightMinInt = parseInt(shipWeightMin, 10);
    var shipWeightMax = shipping[i].getAttribute("data-maxweight");
    var shipWeightMaxInt = parseInt(shipWeightMax, 10);

    if (shipItemsMaxInt != 0 && shipItemsMaxInt < countItemInt) {
      shipping[i].style.display = "none";
      countShip += 1;
    } else if (shipItemsMinInt != 0 && shipItemsMinInt > countItemInt) {
      shipping[i].style.display = "none";
      countShip += 1;
    } else if (shipWeightMaxInt != 0 && shipWeightMaxInt < countWeightInt) {
      shipping[i].style.display = "none";
      countShip += 1;
    } else if (shipWeightMinInt != 0 && shipWeightMinInt > countWeightInt) {
      shipping[i].style.display = "none";
      countShip += 1;
    } else {
      shipping[i].style.display = "block";
      countShip -= 1;
    }
  }


  if (shippingNumber <= countShip) {
    infoModal(langGen("StopNoShipping"));
    return false;
  }

  document.getElementById("buyProduct").style.display = "none";
  document.getElementById("buyBuying").style.display = "block";
}
function backToCustomer() {
  document.getElementById("buyBuying").style.display = "block";
  document.getElementById("buyShipping").style.display = "none";
}
function gotoShipping() {
  if (!checkCustomerdata()) {
    return;
  }
  document.getElementById("buyBuying").style.display = "none";
  document.getElementById("buyShipping").style.display = "block";
}
function backToShipping() {
  document.getElementById("buyShipping").style.display = "block";
  document.getElementById("buyAccept").style.display = "none";
}
function gotoAccept() {
  if (!checkShippingdata()) {
    return;
  }
  document.getElementById("buyShipping").style.display = "none";
  document.getElementById("buyAccept").style.display = "block";

  // Update pricing
  //updatePriceCount();

  // Customer data
  //var parNumber = document.getElementById("buyProductcount").value;
  var parEmail = document.getElementById("buyEmail").value
  var parName = document.getElementById("buyName").value;
  var parPass = document.getElementById("buyPassword").value;
  var parAdd = document.getElementById("buyAddress").value;
  var parPhone = document.getElementById("buyPhone").value;
  var parCity = document.getElementById("buyCity").value;
  var parZip = document.getElementById("buyZip").value;
  var parCountry = document.getElementById("buyCountry").value;

  // Shipping data
  var shippingName = "";
  var shippingPrice = "";
  var shippingVat = "";
  var radios = document.getElementsByName('shipping');
  for (var i = 0, length = radios.length; i < length; i++) {
    if (radios[i].checked) {
      shippingName = radios[i].getAttribute("data-name");
      shippingPrice = radios[i].getAttribute("data-price");
      shippingVat = radios[i].getAttribute("data-vat");
      break;
    }
  }

  // Show data
  //document.getElementById("checkProduct").innerHTML = document.getElementById("productname").value;
  //document.getElementById("checkNumber").innerHTML = parNumber;

  var totalPriceWithoutVat = 0;
  var totalPriceVat = 0;
  var valuta = "";

  var count = document.getElementsByClassName('productcount');
  for (var i = 0, length = count.length; i < length; i++) {
    var tmpRawPrice = parseFloatSafe(count[i].getAttribute("data-rawprice"));
    var tmpRawVat = parseFloatSafe(count[i].getAttribute("data-rawvat"));
    var number = parseFloatSafe(count[i].value);

    totalPriceWithoutVat += tmpRawPrice * number;
    totalPriceVat += tmpRawVat * number;

    valuta = count[i].getAttribute("data-valuta");
  }
  var totalPriceAndShipping = totalPriceWithoutVat + totalPriceVat + parseFloatSafe(shippingPrice) + parseFloatSafe(shippingVat);

  if (document.getElementsByClassName("checkNumber")[0]) {
    var parNumber = "";
    var count = document.getElementsByClassName('productcount');
    for (var i = 0, length = count.length; i < length; i++) {
      if (parNumber != "") {
        parNumber += ","
      }
      parNumber += count[i].value;
    }
    document.getElementsByClassName("checkNumber")[0].innerHTML = parNumber;
  }

  document.getElementById("checkPrice").innerHTML = (totalPriceWithoutVat + totalPriceVat).toFixed(2) + " " + valuta;
  document.getElementById("checkPriceVat").innerHTML = totalPriceVat.toFixed(2) + " " + valuta;
  document.getElementById("checkShipping").innerHTML = shippingName;
  document.getElementById("checkShippingPrice").innerHTML = (parseFloatSafe(shippingPrice) + parseFloatSafe(shippingVat)).toFixed(2) + " " + valuta;
  document.getElementById("checkShippingPriceVat").innerHTML = parseFloatSafe(shippingVat).toFixed(2) + " " + valuta;
  document.getElementById("checkPriceTotal").innerHTML = totalPriceAndShipping.toFixed(2) + " " + valuta;
  document.getElementById("checkPriceTotalVat").innerHTML = (totalPriceVat + parseFloatSafe(shippingVat)).toFixed(2) + " " + valuta;

  document.getElementById("checkName").innerHTML = parName;
  document.getElementById("checkEmail").innerHTML = parEmail;
  document.getElementById("checkPhone").innerHTML = parPhone;
  document.getElementById("checkAddress").innerHTML = parAdd;
  document.getElementById("checkCity").innerHTML = parCity;
  document.getElementById("checkZip").innerHTML = parZip;
  document.getElementById("checkCountry").innerHTML = parCountry;
  document.getElementById("checkCompany").innerHTML = document.getElementById("buyCompany").value;
}

function checkCustomerdata() {
  var parEmail = document.getElementById("buyEmail").value;
  var parName = document.getElementById("buyName").value;
  var parPass = document.getElementById("buyPassword").value;
  var parAdd = document.getElementById("buyAddress").value;
  //var parPhone = document.getElementById("buyPhone").value;
  var parCity = document.getElementById("buyCity").value;
  var parZip = document.getElementById("buyZip").value;
  var parCountry = document.getElementById("buyCountry").value;

  if (parName == "") {
    infoModal(langGen("StopName"));
    return false;
  }
  if (parEmail == "" || !validateEmail(parEmail)) {
    infoModal(langGen("StopEmail"));
    return false;
  }
  if (parPass == "" || parPass.length <= 4) {
    infoModal(langGen("StopPass"));
    return false;
  }

  if (parAdd == "") {
    infoModal(langGen("StopAddress"));
    return false;
  }
  if (parZip == "") {
    infoModal(langGen("StopZip"));
    return false;
  }
  if (parCity == "") {
    infoModal(langGen("StopCity"));
    return false;
  }
  if (parCountry == "") {
    infoModal(langGen("StopCountry"));
    return false;
  }
  return true;
}

function checkShippingdata() {
  var shippingChoice = false;
  var radios = document.getElementsByName('shipping');
  for (var i = 0, length = radios.length; i < length; i++) {
    if (radios[i].checked) {
      shippingChoice = true;
    }
  }
  if (!shippingChoice) {
    infoModal(langGen("ChooseShip"));
    return false;
  }
  return true;
}

// Do the buy
function doTheBuy() {
  var buttons = document.getElementById("dothebuybuttons");
  buttons.style.display = "none";

  var xhr;
  var url = "/basket/buynow";

  // Product
  var parId = document.getElementById("id").value;
  if (parId == "") {
    infoModal(langGen("ErrorContact"));
    buttons.style.display = "block";
    return;
  }
  var multi = document.getElementById("id").getAttribute("data-multi");

  // Customer data
  var parNumber = "";
  var count = document.getElementsByClassName('productcount');
  for (var i = 0, length = count.length; i < length; i++) {
    if (parNumber != "") {
      parNumber += ","
    }
    parNumber += count[i].value;
  }

  var parEmail = document.getElementById("buyEmail").value
  var parName = document.getElementById("buyName").value;
  var parPass = document.getElementById("buyPassword").value;
  var parAdd = document.getElementById("buyAddress").value;
  var parPhone = document.getElementById("buyPhone").value;
  var parCity = document.getElementById("buyCity").value;
  var parZip = document.getElementById("buyZip").value;
  var parCountry = document.getElementById("buyCountry").value;


  // Shipping data
  var parShipping = "";
  var radios = document.getElementsByName('shipping');
  for (var i = 0, length = radios.length; i < length; i++) {
    if (radios[i].checked) {
      parShipping = radios[i].value;
    }
  }
  var parShippingDetails = document.getElementById("shippingdetails").value;

  // Message
  var cusMsg = "";
  if (document.getElementById("custommessage")) {
    cusMsg = document.getElementById("custommessage").value;
  }

  // Accept
  var parAcc = document.getElementById("acceptBuy").checked;
  if (!parAcc) {
    infoModal(langGen("AcceptTerms"));
    buttons.style.display = "block";
    return;
  }

  // Email receipt
  var sendMail = "true";
  var parEmailSend = document.getElementById("sendEmail").checked;
  if (!parEmailSend) {
    sendMail = "false";
  }


  var recaptcha = "";
  var recaptchaDom = document.getElementById("g-recaptcha-response");
  if (typeof (recaptchaDom) != 'undefined' && recaptchaDom != null) {
    recaptcha = recaptchaDom.value;
  }

  var params = {
    id: parId,
    multi: multi,
    productcount: parNumber,
    email: parEmail,
    name: parName,
    password: parPass,
    address: parAdd,
    phone: parPhone,
    city: parCity,
    zip: parZip,
    country: parCountry,
    company: document.getElementById("buyCompany").value,
    companyid: document.getElementById("buyCompanyId").value,
    shipping: parShipping,
    shippingDetails: parShippingDetails,
    sendmail: sendMail,
    cusmsg: cusMsg,
    grecaptcharesponse: recaptcha
  }

  // Arg, who is still using IE !!!
  //data = Object.entries(params)
  //  .map(([key, val]) => `${key}=${encodeURIComponent(val)}`)
  //  .join('&');
  data = Object.entries(params).map(function (_ref) {
    var key = _ref[0],
      val = _ref[1];
    return key + "=" + encodeURIComponent(val);
  }).join('&');

  xhr = new XMLHttpRequest();
  xhr.onreadystatechange = function () {
    if (this.readyState == 4 && this.status == 200) {
      buySuccess(this);
    }
  };
  xhr.open("POST", url);
  xhr.setRequestHeader("Content-Type", "application/x-www-form-urlencoded");
  xhr.send(data);
}

// Check the response after buying
function buySuccess(xhr) {
  console.log(xhr.responseText);

  if (!isError(xhr.responseText)) {
    document.getElementById("buyAccept").style.display = "none";
    document.getElementById("buyBuyingHeading").style.display = "none";

    document.getElementById("buyCongratulations").style.display = "block";
    document.getElementById("allReceipts").innerHTML = xhr.responseText;

    document.getElementById("buyNow").style.setProperty("max-width", "800px", "important");

  } else {
    infoModal(xhr.responseText);
    var buttons = document.getElementById("dothebuybuttons");
    buttons.style.display = "block";
  }
}


/*
  UI
*/
function updatePriceTotal() {
  var count = document.getElementsByClassName('updatedPrice');
  var priceTotal = 0;
  for (var i = 0, length = count.length; i < length; i++) {
    var parNumber = count[i].value;
    if (parNumber == "" || parNumber == "0" || isNaN(parNumber)) {
      return false;
    }
    priceTotal += parseFloatSafe(parNumber);
  }

  var shippingPrice = "";
  var shippingVat = "";
  var radios = document.getElementsByName('shipping');
  for (var i = 0, length = radios.length; i < length; i++) {
    if (radios[i].checked) {
      shippingPrice = radios[i].getAttribute("data-price");
      shippingVat = radios[i].getAttribute("data-vat");
      break;
    }
  }
  priceTotal += parseFloatSafe(shippingPrice);
  priceTotal += parseFloatSafe(shippingVat);

  document.getElementById("priceTotal").value = priceTotal.toFixed(2);
}
function updatePriceCount(el) {
  var id = el.getAttribute("id");
  var price = parseFloatSafe(el.getAttribute("data-rawPrice"));
  var vat = parseFloatSafe(el.getAttribute("data-rawVat"));
  var numbers = parseFloatSafe(el.value);
  document.getElementById(el.getAttribute("data-id") + "-updatedPrice").value = (price * numbers + vat * numbers).toFixed(2);
  document.getElementById(el.getAttribute("data-id") + "-updatedVat").value = (vat * numbers).toFixed(2);

  document.getElementById(el.getAttribute("data-id") + "-checkNumber").innerHTML = numbers;
  updatePriceTotal();
}

// Colorize input field
function colorStatusOk(id) {
  document.getElementById(id).classList.remove("is-info");
  document.getElementById(id).classList.remove("is-danger");
  document.getElementById(id).classList.add("is-success");
}
function colorStatusNot(id) {
  document.getElementById(id).classList.remove("is-success");
  document.getElementById(id).classList.remove("is-info");
  document.getElementById(id).classList.add("is-danger");
}

function updatePrice(el) {
  var id = el.getAttribute("id");
  var input = document.getElementById(id).value;
  var maxitems = document.getElementById(id).getAttribute("max");
  if (input == "0" || input == "" || parseInt(input) > parseInt(maxitems)) {
    document.getElementById(id).classList.remove("is-info");
    document.getElementById(id).classList.add("is-danger");
  } else {
    document.getElementById(id).classList.remove("is-info");
    document.getElementById(id).classList.remove("is-danger");
    document.getElementById(id).classList.add("is-success");
  }
}
function updateInput(el) {
  var id = el.getAttribute("id");
  var input = document.getElementById(id).value;
  if (input.length >= 1) {
    colorStatusOk(id);
  } else {
    colorStatusNot(id);
  }
}
function updatePassword(el) {
  var id = el.getAttribute("id");
  var input = document.getElementById(id).value;
  if (input.length > 4) {
    colorStatusOk(id);
  } else {
    colorStatusNot(id);
  }
}
function validateEmail(email) {
  if (/^\w+([\.-]?\w+)*@\w+([\.-]?\w+)*(\.\w{2,3})+$/.test(email)) {
    return true;
  } else {
    return false;
  }
}
function updateEmail(el) {
  var id = el.getAttribute("id");
  var input = document.getElementById(id).value;
  if (validateEmail(input)) {
    colorStatusOk(id);
  } else {
    colorStatusNot(id);
  }
}
function validatePhone(phone) {
  var phone1 = /^\(?([0-9]{3})\)?[-. ]?([0-9]{3})[-. ]?([0-9]{4})$/ // 10 digits
  var phone2 = /^\+?([0-9]{2})\)?[-. ]?([0-9]{4})[-. ]?([0-9]{4})$/ // +-sign + 10 digits
  var phone3 = /^\d{8}$/ // 8 digits
  var phoneFinal = phone.replace(/\s/g, '');
  if (phone1.test(phoneFinal) || phone2.test(phoneFinal) || phone3.test(phoneFinal)) {
    return true;
  } else {
    return false;
  }
}
function updatePhone(el) {
  var id = el.getAttribute("id");
  var input = document.getElementById(id).value;
  if (validatePhone(input)) {
    colorStatusOk(id);
  } else {
    colorStatusNot(id);
  }
}
function updateCompany(el) {
  var id = el.getAttribute("id");
  var input = document.getElementById(id).value;
  if (input.length >= 1) {
    document.getElementById(id).classList.remove("is-info");
    document.getElementById(id).classList.add("is-success");
  } else {
    document.getElementById(id).classList.remove("is-success");
    document.getElementById(id).classList.add("is-info");
  }
}

function updateZip() {
  var country = document.getElementById("buyCountry").value;
  var zip = document.getElementById("buyZip").value;
  if (zip.length >= 1) {
    colorStatusOk("buyZip");
  } else {
    colorStatusNot("buyZip");
  }

  // Danish
  if (country == "Danmark") {
    if (zip.length == 4) {
      xhr = new XMLHttpRequest();
      xhr.onreadystatechange = function () {
        if (this.readyState == 4 && this.status == 200) {
          updateCityDKUpdate(this);
        }
      };
      xhr.open("GET", "https://dawa.aws.dk/postnumre/" + zip);
      xhr.send(xhr);
    } else {
      colorStatusNot("buyZip");
      colorStatusNot("buyCity");
    }
  }

}
function updateCityDKUpdate(xhr) {
  var suggestion = JSON.parse(xhr.responseText);
  document.getElementById("buyCity").value = suggestion["navn"];
  colorStatusOk("buyCity");
}


/*
  Info modal
*/
const $closeInfoModal = document.getElementById("buy-info-modal");
if ($closeInfoModal != null) {
  document.getElementById("buy-info-modal").addEventListener('click', function () {
    document.getElementById("buy-info-modal").classList.remove("is-active");
    document.documentElement.style.overflow = "auto";
  });
}

function infoModal(text) {
  var element = document.getElementById("buy-info-modal");
  if (element != null) {
    element.classList.toggle("is-active");
    var content = document.getElementById("buy-info-modal-content");
    content.innerHTML = text;
  }
}