import { Controller } from '@hotwired/stimulus';

const MAX_LOGO_PREVIEW_HEIGHT = 80;
const MAX_LOGO_PREVIEW_WIDTH = 220;

export class CreatorSettingsController extends Controller {
  static targets = ['previewLogo'];

  previewLogo(event) {
    const {
      target: {
        files: [firstFile],
      },
    } = event;

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
            height = (width / height) * MAX_LOGO_PREVIEW_WIDTH;
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
}
