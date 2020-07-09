function initializePaymentPointers() {
  var userPointer = document.getElementById('author-payment-pointer');
  var basePointer = document.getElementById('base-payment-pointer');
  var meta = document.querySelector("meta[name='monetization']");

  if (userPointer) {
    meta.content = userPointer.dataset.paymentPointer;
  } else if (basePointer) {
    meta.content = basePointer.dataset.paymentPointer;;
  }
}
