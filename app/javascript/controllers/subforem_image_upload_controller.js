import { Controller } from '@hotwired/stimulus';

const MAX_PREVIEW_HEIGHT = 80;

/**
 * Manages image upload interactions on the Subforem edit page.
 */
export class SubforemImageUploadController extends Controller {
  static targets = ['preview'];

  /**
   * Displays a preview of the image selected by the user.
   *
   * @param {Event} event
   */
  previewImage(event) {
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
      image.className = 'w-full h-full object-cover rounded';

      // The preview image is purely visual so no need to communicate this to assistive technology.
      image.alt = 'preview of selected image';

      image.addEventListener(
        'load',
        (event) => {
          let {
            target: { width, height },
          } = event;

          if (this.previewTarget.firstElementChild) {
            this.previewTarget.replaceChild(
              image,
              this.previewTarget.firstElementChild,
            );
          } else {
            this.previewTarget.appendChild(image);
          }

          // Scale the image to fit the preview container
          const containerWidth = this.previewTarget.offsetWidth;
          const containerHeight = this.previewTarget.offsetHeight;

          if (height > containerHeight) {
            width = (containerHeight / height) * width;
            height = containerHeight;
          }

          if (width > containerWidth) {
            height = (containerWidth / width) * height;
            width = containerWidth;
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
 * Default export for compatibility with Stimulus controller loading.
 */
export default SubforemImageUploadController;
