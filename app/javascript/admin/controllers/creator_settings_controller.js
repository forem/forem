import { Controller } from '@hotwired/stimulus';
import { brightness } from '../../utilities/color/accentCalculator';

const MAX_LOGO_PREVIEW_HEIGHT = 80;
const MAX_LOGO_PREVIEW_WIDTH = 220;

/**
 * Manages interactions on the Creator Settings page.
 */
export class CreatorSettingsController extends Controller {
  static targets = ['previewLogo'];

  /**
   * Displays a preview of the image selected by the user.
   *
   * @param {Event} event
   */
  previewLogo(event) {
    const {
      target: {
        files: [firstFile],
      },
    } = event;

    if (!firstFile) {
      // Most likely the user cancelled the file selection.
      return;
    }

    const reader = new FileReader();

    reader.onload = () => {
      const imageURL = reader.result;
      const image = document.createElement('img');
      image.src = imageURL;

      // The logo preview image is purely visual so no need to communicate this to assistive technology.
      image.alt = 'preview of logo selected';

      image.addEventListener(
        'load',
        (event) => {
          let {
            target: { width, height },
          } = event;

          if (height > MAX_LOGO_PREVIEW_HEIGHT) {
            width = (width / height) * MAX_LOGO_PREVIEW_HEIGHT;
            height = MAX_LOGO_PREVIEW_HEIGHT;
          }

          if (width > MAX_LOGO_PREVIEW_WIDTH) {
            width = MAX_LOGO_PREVIEW_WIDTH;
            height = (height / width) * MAX_LOGO_PREVIEW_WIDTH;
          }

          image.style.width = `${width}px`;
          image.style.height = `${height}px`;

          this.previewLogoTarget.replaceChild(
            image,
            this.previewLogoTarget.firstChild,
          );
        },
        { once: true },
      );
    };

    reader.readAsDataURL(firstFile);
  }

  /**
   * Updates ths branding/colors on the Creator Settings Page.
   *
   * @param {Event} event
   */
  updateBranding(event) {
    const { value: color } = event.target;

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
}
