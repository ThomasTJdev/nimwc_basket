/*
  Accounting
*/
const $buyToModal = Array.prototype.slice.call(document.querySelectorAll('.receiptItem'), 0);
if ($buyToModal.length > 0) {
  $buyToModal.forEach(el => {
    el.addEventListener('click', () => {

      var element = document.getElementById("receipt-modal")
      if (element != null) {
        element.classList.toggle("is-active");
      }

      var childs = el.querySelectorAll("td")
      document.getElementById("modalReceipt").innerHTML = childs[0].innerText;
      document.getElementById("modalName").innerHTML = childs[1].innerText;
      document.getElementById("modalEmail").innerHTML = childs[2].innerText;
      document.getElementById("modalCreation").innerHTML = childs[3].innerText;
      document.getElementById("modalModified").innerHTML = childs[4].innerText;
      document.getElementById("modalShipped").innerHTML = childs[5].innerText;

      document.getElementById("downloadreceipt").href = "/basket/getreceiptpdf/" + el.id + "_" + childs[2].innerText.replace(/\./g, '_').replace(/\@/g, '_') + ".pdf";

      var actions = document.getElementById("accountingActions");
      if (el.classList.contains("cancelled")) {
        actions.style.display = "none";
      } else {
        actions.style.display = "block";
      }

      // This assigns purchase_id
      var x = document.getElementsByClassName("receipt_id");
      for (var i = 0; i < x.length; i++) {
        var str = x[i].value;
        x[i].value = el.id;
      }
    });
  });
}
// Close buy modal
const $closeCredsModal = document.getElementById("receipt-modal");
if ($closeCredsModal != null) {
  document.getElementById("close-buy").addEventListener('click', function () {
    document.getElementById("receipt-modal").classList.remove("is-active");
    document.documentElement.style.overflow = "auto";
  });
}


/*
  Products
*/
// Products modal
const $productEditRow = Array.prototype.slice.call(document.querySelectorAll('.productEdit'), 0);
if ($productEditRow.length > 0) {
  $productEditRow.forEach(el => {
    el.addEventListener('click', () => {

      var element = document.getElementById("product-modal")
      if (element != null) {
        element.classList.toggle("is-active");
      }

      var childs = el.querySelectorAll("td");
      document.getElementById("productEditIdentifier").value = childs[0].innerText;
      document.getElementById("productEditName").value = childs[1].innerText;
      document.getElementById("productEditDescription").value = childs[2].innerText;
      document.getElementById("productEditPrice").value = childs[3].innerText;
      document.getElementById("productEditVat").value = childs[4].innerText;
      document.getElementById("productEditValuta").value = childs[5].innerText;
      document.getElementById("productEditWeight").value = childs[6].innerText;
      document.getElementById("productEditQuantity").value = childs[7].innerText;

      if (childs[9].innerText == "Active") {
        document.getElementById("productEditActive").value = "1";
      } else {
        document.getElementById("productEditActive").value = "0";
      }

      document.getElementById("formProduct").action = "/basket/products/edit";

      document.getElementById("id").value = el.id;
    });
  });
}

// Close Products modal
const $closeProductsModal = document.getElementById("product-modal");
if ($closeProductsModal != null) {
  document.getElementById("product-close").addEventListener('click', function () {
    document.getElementById("product-modal").classList.remove("is-active");
    document.documentElement.style.overflow = "auto";
  });
}

// Close Products info modal
const $closeInfoProductsModal = document.getElementById("product-info-modal");
if ($closeInfoProductsModal != null) {
  document.getElementById("product-info-modal").addEventListener('click', function () {
    document.getElementById("product-info-modal").classList.remove("is-active");
    document.documentElement.style.overflow = "auto";
  });
}

// Open Products info modal
function infoProductsModal(text) {
  var element = document.getElementById("product-info-modal");
  if (element != null) {
    element.classList.toggle("is-active");
    var content = document.getElementById("product-info-modal-content");
    content.innerHTML = text;
  }
}

// Open Products add modal
function productAdd() {
  var element = document.getElementById("product-modal")
  element.classList.toggle("is-active");

  document.getElementById("productEditIdentifier").value = "";
  document.getElementById("productEditName").value = "";
  document.getElementById("productEditDescription").value = "";
  document.getElementById("productEditPrice").value = "";
  document.getElementById("productEditVat").value = "";
  document.getElementById("productEditValuta").value = "";

  document.getElementById("formProduct").action = "/basket/products/add";

  document.getElementById("id").value = "";
}



/*
  Shipping
*/
// Shipping modal
const $shippingEditRow = Array.prototype.slice.call(document.querySelectorAll('.shippingEdit'), 0);
if ($shippingEditRow.length > 0) {
  $shippingEditRow.forEach(el => {
    el.addEventListener('click', () => {

      var element = document.getElementById("shipping-modal")
      if (element != null) {
        element.classList.toggle("is-active");
      }

      var childs = el.querySelectorAll("td")
      document.getElementById("shippingEditName").value = childs[0].innerText;
      document.getElementById("shippingEditDescription").value = childs[1].innerText;
      document.getElementById("shippingEditPrice").value = childs[2].innerText;
      document.getElementById("shippingEditVat").value = childs[3].innerText;
      document.getElementById("shippingEditValuta").value = childs[4].innerText;
      document.getElementById("shippingEditMinitems").value = childs[5].innerText;
      document.getElementById("shippingEditMaxitems").value = childs[6].innerText;
      document.getElementById("shippingEditMinweight").value = childs[7].innerText;
      document.getElementById("shippingEditMaxweight").value = childs[8].innerText;

      document.getElementById("formShipping").action = "/basket/shipping/edit";

      document.getElementById("id").value = el.id;
    });
  });
}

// Close Shipping modal
const $closeShippingModal = document.getElementById("shipping-modal");
if ($closeShippingModal != null) {
  document.getElementById("shipping-close").addEventListener('click', function () {
    document.getElementById("shipping-modal").classList.remove("is-active");
    document.documentElement.style.overflow = "auto";
  });
}

// Close Shipping info modal
const $closeInfoShippingModal = document.getElementById("shipping-info-modal");
if ($closeInfoShippingModal != null) {
  document.getElementById("shipping-info-modal").addEventListener('click', function () {
    document.getElementById("shipping-info-modal").classList.remove("is-active");
    document.documentElement.style.overflow = "auto";
  });
}

// Open Shipping info modal
function infoShippingModal(text) {
  var element = document.getElementById("shipping-info-modal");
  if (element != null) {
    element.classList.toggle("is-active");
    var content = document.getElementById("shipping-info-modal-content");
    content.innerHTML = text;
  }
}

// Open Products add modal
function shippingAdd() {
  var element = document.getElementById("shipping-modal")
  element.classList.toggle("is-active");

  document.getElementById("shippingEditName").value = "";
  document.getElementById("shippingEditDescription").value = "";
  document.getElementById("shippingEditPrice").value = "";
  document.getElementById("shippingEditVat").value = "";
  document.getElementById("shippingEditValuta").value = "";

  document.getElementById("formShipping").action = "/basket/shipping/add";

  document.getElementById("id").value = "";
}