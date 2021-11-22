import { Controller } from '@hotwired/stimulus';
import { WCAGColorContrast } from '../../utilities/colorContrast';
const MAX_LOGO_PREVIEW_HEIGHT = 80;
const MAX_LOGO_PREVIEW_WIDTH = 220;

/**
 * Manages interactions on the Creator Settings page.
 */
export class CreatorSettingsController extends Controller {
  static targets = ['previewLogo', 'colorContrastError', 'brandColor'];

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
   * Validates the color contrast on brand color picker
   * for accessibility.
   *
   * @param {Event} event
   */
  validateColorContrast(event) {
    const { value: color } = event.target;

    if (WCAGColorContrast.isLow(color)) {
      this.colorContrastErrorTarget.classList.remove('hidden');
    } else {
      this.colorContrastErrorTarget.classList.add('hidden');
    }
  }

  /**
   * Validates the form and prevents a submission if the
   * color contrast is low.
   *
   * @param {Event} event
   */
  formValidations(event) {
    const { value: color } = this.brandColorTarget;
    if (WCAGColorContrast.isLow(color)) {
      this.colorContrastErrorTarget.classList.remove('hidden');
      //  we don't want the form to submit if the contrast is low
      event.preventDefault();
    }
  }
}
