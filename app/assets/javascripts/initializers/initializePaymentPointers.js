function initializePaymentPointers() {
  var userPointer = document.getElementById('author-payment-pointer');
  var basePointer = document.getElementById('base-payment-pointer');
  var meta = document.querySelector("meta[name='monetization']");
  
  if (userPointer) {
    meta.content = userPointer.dataset.paymentPointer;
    console.log(meta.content)
  } else {
    meta.content = basePointer.dataset.paymentPointer;;
    console.log(meta.content)
  }
}
