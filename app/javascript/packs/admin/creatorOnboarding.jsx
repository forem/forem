import { replaceTextInputWithColorPicker } from '../../colorPickers/replaceTextInputWithColorPicker';
import { isLowContrast } from '@utilities/color/contrastValidator';
import { brightness } from '@utilities/color/accentCalculator';

const vanillaPicker = document.getElementById(
  'creator_settings_form_primary_brand_color_hex',
);
const contrastErrorMessage = document.getElementById('color-contrast-error');
const finishButton = document.getElementById('finish-button');

if (vanillaPicker) {
  replaceTextInputWithColorPicker({
    input: vanillaPicker,
    labelText: 'Brand color',
    onChange: handleValidationsAndUpdates,
  });

  // We don't want the form to submit if the contrast is too low
  finishButton.addEventListener('click', (event) => {
    const { value: color } = document.getElementById(
      'creator_settings_form_primary_brand_color_hex',
    );

    if (isLowContrast(color)) {
      event.preventDefault();
    }
  });
}

/**
 * Validates the color contrast for accessibility,
 * if the contrast is okay, it updates the branding,
 * else it displays the error.
 *
 * @param {string} color The color hex code
 */
function handleValidationsAndUpdates(color) {
  if (isLowContrast(color)) {
    contrastErrorMessage.innerText =
      'The selected color must be darker for accessibility purposes.';
  } else {
    updateBranding(color);
    contrastErrorMessage.innerText = '';
  }
}

/**
 * Updates the branding/colors on the Creator Settings Page
 * by overriding the accent-color in the :root object
 *
 * @param {String} color The color hex code
 */
function updateBranding(color) {
  document.documentElement.style.setProperty('--accent-brand', color);

  // We need to recalculate '--accent-brand-darker' in javascript as it's
  // currently being calculated in ruby. It is used for the hover effect
  // over the button.
  // 0.85 represents the brightness value set in Ruby to calculate
  // '--accent-brand-darker'
  document.documentElement.style.setProperty(
    '--accent-brand-darker',
    brightness(color, 0.85),
  );
}
