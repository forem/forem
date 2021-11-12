import { Controller } from '@hotwired/stimulus';

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

      image.addEventListener(
        'load',
        (event) => {
          let {
            target: { width, height },
          } = event;

          if (height > 80) {
            width = (width / height) * 80;
            height = 80;
          }

          image.style.width = `${width}px`;
          image.style.height = `${height}px`;
          image.src = imageURL;

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
