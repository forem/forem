import { Controller } from 'stimulus';

export class SvgIconUploadController extends Controller {
  static targets = [
    'svgIconContent',
    'svgIconPreview',
    'svgIconMessageValidate',
    'navId',
  ];

  selectSvgIcon(event) {
    this.clearInvalidIconTypeMessage();

    const icon = event.target.files[0];
    if (icon.type !== 'image/svg+xml' && icon.type !== 'image/svg') {
      this.invalidIconTypeMessage(icon.type);
      const navigationLinkId = this.navIdTarget.attributes['nav-link-id'].value;

      const ableToClearSvgIconContent =
        !navigationLinkId && this.svgIconContentTarget.value;
      if (ableToClearSvgIconContent) {
        this.svgIconContentTarget.value = null;
        this.setSvgIconPreview(null);
      }
      return;
    }

    const reader = new FileReader();
    reader.readAsText(icon);

    reader.onload = (content) => {
      const result = content.target.result;
      this.svgIconContentTarget.value = result;
      this.setSvgIconPreview(result);
    };
  }

  setSvgIconPreview(content) {
    this.svgIconPreviewTarget.innerHTML = content;
    if (content) this.svgIconPreviewTarget.classList.add('pb-3');
    else if (this.svgIconPreviewTarget.classList.length !== 0)
      this.svgIconPreviewTarget.classList.remove('pb-3');
  }

  clearInvalidIconTypeMessage() {
    if (this.svgIconMessageValidateTarget.classList.length !== 0) {
      this.svgIconMessageValidateTarget.classList.remove(
        'alert',
        'alert-danger',
      );
      this.svgIconMessageValidateTarget.innerHTML = null;
    }
  }

  invalidIconTypeMessage(type) {
    this.svgIconMessageValidateTarget.classList.add('alert', 'alert-danger');
    this.svgIconMessageValidateTarget.innerHTML = `'${type}' is a invalid Icon type`;
  }
}
