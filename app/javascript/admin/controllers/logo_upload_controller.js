import { Controller } from '@hotwired/stimulus';

const MAX_LOGO_PREVIEW_HEIGHT = 80;

/**
 * Manages interactions on the Creator Settings page.
 */
export class LogoUploadController extends Controller {
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
      image.className = 'site-logo__img';

      // The logo preview image is purely visual so no need to communicate this to assistive technology.
      image.alt = 'preview of logo selected';

      image.addEventListener(
        'load',
        (event) => {
          let {
            target: { width, height },
          } = event;

          if (this.previewLogoTarget.firstElementChild) {
            this.previewLogoTarget.replaceChild(
              image,
              this.previewLogoTarget.firstElementChild,
            );
          } else {
            this.previewLogoTarget.appendChild(image);
          }

          const maxLogoPreviewWidth = parseInt(
            getComputedStyle(image).getPropertyValue('--max-width'),
            10,
          );

          if (height > MAX_LOGO_PREVIEW_HEIGHT) {
            width = (MAX_LOGO_PREVIEW_HEIGHT / height) * width;
            height = MAX_LOGO_PREVIEW_HEIGHT;
          }

          if (width > maxLogoPreviewWidth) {
            height = (maxLogoPreviewWidth / width) * height;
            width = maxLogoPreviewWidth;
          }

          image.width = width;
          image.height = height;
        },
        { once: true },
      );
    };

    reader.readAsDataURL(firstFile);
  }
}

/**
 * It looks weird having this default export along with the named export
 * LogoUploadController, but the reason it's here is so the admin pack
 * app/javascript/packs/admin.js file can load it with the rest of the
 * admin Stimulus controllers via
 * const context = require.context('admin/controllers', true, /.js$/);
 */
export default LogoUploadController;
