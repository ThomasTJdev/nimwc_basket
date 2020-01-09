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
  updatePriceCount();

  // Customer data
  var parNumber = document.getElementById("buyProductcount").value;
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
    }
  }

  // Show data
  document.getElementById("checkProduct").innerHTML = document.getElementById("productname").value;
  document.getElementById("checkNumber").innerHTML = parNumber;
  document.getElementById("checkPrice").innerHTML = document.getElementById("updatedPrice").value;
  document.getElementById("checkPriceVat").innerHTML = document.getElementById("updatedVat").value;
  document.getElementById("checkShipping").innerHTML = shippingName;
  document.getElementById("checkShippingPrice").innerHTML = shippingPrice;
  document.getElementById("checkShippingPriceVat").innerHTML = shippingVat;
  document.getElementById("checkPriceTotal").innerHTML = document.getElementById("priceTotal").value;
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
  var parNumber = document.getElementById("buyProductcount").value;
  var parEmail = document.getElementById("buyEmail").value
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
  if (parPass == "") {
    infoModal(langGen("StopPass"));
    return false;
  }
  if (parNumber == "") {
    infoModal(langGen("StopQuantity"));
    return false;
  }
  if (parNumber == "0") {
    infoModal(langGen("StopQuantity"));
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
  var xhr;
  var url = "/basket/buynow";

  // Product
  var parId = document.getElementById("id").value;
  if (parId == "") {
    infoModal(langGen("ErrorContact"));
    return;
  }

  // Customer data
  var parNumber = document.getElementById("buyProductcount").value;
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

  // Accept
  var parAcc = document.getElementById("acceptBuy").checked;
  if (!parAcc) {
    infoModal(langGen("AcceptTerms"));
    return;
  }

  var recaptcha = "";
  var recaptchaDom = document.getElementById("g-recaptcha-response");
  if (typeof (recaptchaDom) != 'undefined' && recaptchaDom != null) {
    recaptcha = recaptchaDom.value;
  }

  var params = {
    id: parId,
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
    shipping: parShipping,
    shippingDetails: parShippingDetails,
    grecaptcharesponse: recaptcha
  }

  data = Object.entries(params)
    .map(([key, val]) => `${key}=${encodeURIComponent(val)}`)
    .join('&');

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

    document.getElementById("buyNow").style.maxWidth = "800px";


    document.getElementById("buyCongratulations").style.display = "block";
    document.getElementById("allReceipts").innerHTML = xhr.responseText;

  } else {
    infoModal(xhr.responseText);
  }
}


/*
  UI
*/
function updatePriceCount() {
  var price = parseInt(document.getElementById("rawPrice").value, 10);
  var vat = parseInt(document.getElementById("rawVat").value, 10);
  var numbers = parseInt(document.getElementById("buyProductcount").value, 10);
  document.getElementById("updatedPrice").value = price * numbers;
  document.getElementById("updatedVat").value = vat * numbers;

  var shippingPrice = "";
  var shippingVat = "";
  var radios = document.getElementsByName('shipping');
  for (var i = 0, length = radios.length; i < length; i++) {
    if (radios[i].checked) {
      shippingPrice = radios[i].getAttribute("data-price");
      shippingVat = radios[i].getAttribute("data-vat");
    }
  }
  var shippingCost = parseInt(shippingPrice, 10) + parseInt(shippingVat, 10);
  var priceTotal = (price + vat) * numbers + shippingCost;
  document.getElementById("priceTotal").value = priceTotal;
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
  if (input == "0" || input == "" || parseInt(input) > 11) {
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
  if (input.length >= 4) {
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
  if (phone1.test(phone) || phone2.test(phone) || phone3.test(phone)) {
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