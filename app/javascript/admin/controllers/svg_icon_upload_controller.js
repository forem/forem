import { Controller } from 'stimulus';

export default class SvgIconUploadController extends Controller {
  selectSvgIcon(event) {
    const currentNavigationLinkModal = this.targets.scope.data.element.querySelector(
      'div',
    );

    this.clearInvalidIconTypeMessage(currentNavigationLinkModal);

    const svgIconContent = currentNavigationLinkModal.querySelector(
      '#svg-icon-content',
    );

    const icon = event.target.files[0];
    if (icon.type !== 'image/svg+xml') {
      this.invalidIconTypeMessage(currentNavigationLinkModal, icon.type);
      const navigationLinkId = currentNavigationLinkModal.getAttribute(
        'nav-link-id',
      );

      const ableToRemoveSvgIconContent =
        svgIconContent.value && !navigationLinkId;
      if (ableToRemoveSvgIconContent) {
        svgIconContent.value = null;
        this.setSvgIconPreview(currentNavigationLinkModal, null);
      }
      return;
    }

    const reader = new FileReader();
    reader.readAsText(icon);

    reader.onload = (content) => {
      const result = content.target.result;
      svgIconContent.value = result;
      this.setSvgIconPreview(currentNavigationLinkModal, result);
    };
  }

  setSvgIconPreview(document, content) {
    const iconPreview = document.querySelector('#svg-icon-preview');
    iconPreview.innerHTML = content;
    if (content) iconPreview.classList.add('pb-3');
    else if (iconPreview.classList.length !== 0)
      iconPreview.classList.remove('pb-3');
  }

  clearInvalidIconTypeMessage(document) {
    const alertMessage = document.querySelector('#svg-icon-message-validate');
    if (alertMessage.classList.length !== 0) {
      alertMessage.classList.remove('alert', 'alert-danger');
      alertMessage.innerHTML = null;
    }
  }

  invalidIconTypeMessage(document, type) {
    const alertMessage = document.querySelector('#svg-icon-message-validate');
    alertMessage.classList.add('alert', 'alert-danger');
    alertMessage.innerHTML = `'${type}' is a invalid Icon type`;
  }
}
