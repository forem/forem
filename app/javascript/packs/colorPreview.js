/* eslint-disable no-param-reassign */

const preview = document.getElementById('color-select-preview-logo');

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

// updates field bgColor and textColor to targetField respective fields
function updateFields(field, targetField) {
  field.bgColor.value = targetField.bgColor.value;
  field.textColor.value = targetField.textColor.value;
}

// Updates Preview Colors
function updatePreview() {
  preview.style.backgroundColor = textField.bgColor.value;
  preview.style.fill = textField.textColor.value;
}

// Event Watchers
// When color fields change -> updateTextField values and refresh preview
function watchColorFields() {
  updateFields(textField, colorField);
  updatePreview();
}

// When text fields change -> updateColorField values and refresh preview
function watchTextFields(e) {
  if (e.target.value.match(/#[0-9a-f]{6}/gi)) {
    updateFields(colorField, textField);
    updatePreview();
  }
}

function initPreview() {
  if (preview) {
    // Event Listeners
    colorField.bgColor.addEventListener('input', watchColorFields);
    colorField.textColor.addEventListener('input', watchColorFields);
    textField.bgColor.addEventListener('keyup', watchTextFields);
    textField.textColor.addEventListener('keyup', watchTextFields);

    // on init
    updateFields(colorField, textField);
    updatePreview();
    preview.style.display = 'inline-block';
  }
}

initPreview();
window.InstantClick.on('change', initPreview);
