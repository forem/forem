import { Controller } from '@hotwired/stimulus';
import { isLowContrast } from '@utilities/color/contrastValidator';
import { brightness } from '@utilities/color/accentCalculator';

/**
 * Manages interactions on the Creator Settings page.
 */
export class CreatorSettingsController extends Controller {
  static targets = ['colorContrastError', 'brandColor'];

  /**
   * Validates the color contrast for accessibility,
   * if the contrast is okay, it updates the branding,
   * else it displays the error.
   * @param {Event} event
   */
  handleValidationsAndUpdates(event) {
    const { value: color } = event.target;

    if (isLowContrast(color)) {
      this.colorContrastErrorTarget.innerText =
        'The selected color must be darker for accessibility purposes.';
    } else {
      this.updateBranding(color);
      this.colorContrastErrorTarget.innerText = '';
    }
  }

  /**
   * Updates ths branding/colors on the Creator Settings Page.
   * by overriding the accent-color in the :root object
   *
   * @param {String} color
   */
  updateBranding(color) {
    if (!new RegExp(event.target.getAttribute('pattern')).test(color)) {
      return;
    }

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

  /**
   * Prevents a submission of the form if the
   * color contrast is low.
   *
   * @param {Event} event
   */
  formValidations(event) {
    const { value: color } = this.brandColorTarget;
    if (isLowContrast(color)) {
      event.preventDefault();
      this.colorContrastErrorTarget.classList.remove('hidden');
      //  we don't want the form to submit if the contrast is low
    }
  }
}
