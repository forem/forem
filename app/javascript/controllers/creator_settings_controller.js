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

      this.previewLogoTarget.innerHTML = image.outerHTML;
    };

    reader.readAsDataURL(firstFile);
  }
}
