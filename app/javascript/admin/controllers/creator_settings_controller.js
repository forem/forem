import { Controller } from '@hotwired/stimulus';

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

    document.documentElement.style.setProperty('--accent-brand', color);

    // responsible for the hover effect over the button.
    // We need to recalculate this in javascript as it's currently being calculated in ruby
    document.documentElement.style.setProperty(
      '--accent-brand-darker',
      this.updatedBrightness(color, 0.85),
    );
  }

  updatedBrightness(color, amount = 1) {
    const rgbObj = this.hexToRgb(color);
    Object.keys(rgbObj).forEach((key) => {
      rgbObj[key] = Math.round(rgbObj[key] * amount);
    });

    return this.rgbToHex(rgbObj['r'], rgbObj['g'], rgbObj['b']);
  }

  hexToRgb(hex) {
    const result = /^#?([a-f\d]{2})([a-f\d]{2})([a-f\d]{2})$/i.exec(hex);
    return result
      ? {
          r: parseInt(result[1], 16),
          g: parseInt(result[2], 16),
          b: parseInt(result[3], 16),
        }
      : null;
  }

  rgbToHex(r, g, b) {
    return `#${this.rgbParameterToHex(r)}${this.rgbParameterToHex(
      g,
    )}${this.rgbParameterToHex(b)}`;
  }

  rgbParameterToHex(param) {
    const hex = param.toString(16);
    return hex.length == 1 ? `0${hex}` : hex;
  }
}
