function initPreview() {
  const colorField = {
    // input type="color"
    bgColor: document.getElementById('bg-color-colorfield'),
    textColor: document.getElementById('text-color-colorfield'),
  };

  const textField = {
    // input type="text"
    bgColor: document.getElementById('bg-color-textfield'),
    textColor: document.getElementById('text-color-textfield'),
  };

  const preview = document.getElementById('color-select-preview-logo');

  // Assigns input[type='text'] values to input[type='color']
  function updateColorFields() {
    colorField.bgColor.value = textField.bgColor.value;
    colorField.textColor.value = textField.textColor.value;
  }

  // Updating text fields when color fields are changed
  function updateTextFields() {
    textField.bgColor.value = colorField.bgColor.value;
    textField.textColor.value = colorField.textColor.value;
  }

  // Updates Preview Colors
  function updatePreview() {
    preview.style.backgroundColor = textField.bgColor.value;
    preview.style.fill = textField.textColor.value;
  }

  // Event Watchers
  // When color fields change -> updateTextField values and refresh preview
  function watchColorFields() {
    updateTextFields();
    updatePreview();
  }

  // When text fields change -> updateColorField values and refresh preview
  function watchTextFields(e) {
    if (e.target.value.match(/#[0-9a-f]{6}/gi)) {
      updateColorFields();
      updatePreview();
    }
  }

  if (preview) {
    // Event Listeners
    colorField.bgColor.addEventListener('input', watchColorFields);
    colorField.textColor.addEventListener('input', watchColorFields);
    textField.bgColor.addEventListener('keyup', watchTextFields);
    textField.textColor.addEventListener('keyup', watchTextFields);

    // on init
    updateColorFields();
    updatePreview();
    preview.style.display = 'inline-block';
  }
}

initPreview();
window.InstantClick.on('change', initPreview);
