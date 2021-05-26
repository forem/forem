import ModalController from './modal_controller';

export default class ArticlePinnedModalController extends ModalController {
  static targets = ['title', 'pinnedAt', 'pinnedCheckbox'];
  static values = {
    pinnedCheckboxId: String,
    cancelButtonId: String,
    okButtonId: String,
  };

  openModal(event) {
    const { article, checkboxId } = event.detail;

    // set the caller checkbox ID
    this.pinnedCheckboxIdValue = checkboxId;

    // update the modal's HTML with the data coming from the server
    this.titleTarget.setAttribute('href', article.path);
    this.titleTarget.innerText = article.title;

    this.pinnedAtTarget.setAttribute('datetime', article.pinned_at);
    const time = new Date(article.pinned_at);
    const localizedTime = new Intl.DateTimeFormat('default', {
      dateStyle: 'full',
      timeStyle: 'short',
    }).format(time);
    this.pinnedAtTarget.setAttribute('title', localizedTime);
    this.pinnedAtTarget.textContent = localizedTime;

    // open the Preact modal
    this.toggleModal();
  }

  closeModal(event) {
    const target = event?.target;

    if (target === undefined || target?.id === this.cancelButtonIdValue) {
      // find the caller checkbox and uncheck it
      const pinnedCheckbox = this.pinnedCheckboxTargets.filter(
        (cb) => cb.id === this.pinnedCheckboxIdValue,
      )[0];
      pinnedCheckbox.checked = false;
    }

    super.closeModal();
  }
}
