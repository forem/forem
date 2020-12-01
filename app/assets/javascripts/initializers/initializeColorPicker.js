'use strict';

function initializeColorPicker() {
  var pickers = Array.from(document.getElementsByClassName('js-color-field'));

  function colorValueChange(e) {
    var field = e.target;
    var sibling = '';
    if (field.nextElementSibling) {
      sibling = field.nextElementSibling;
    } else {
      sibling = field.previousElementSibling;
    }

    sibling.value = field.value;
  }

  pickers.forEach(function (picker) {
    picker.addEventListener('change', colorValueChange);
  });
}
