import ModalController from './modal_controller';

export default class ArticlePinnedModalController extends ModalController {
  static targets = ['title', 'pinnedAt', 'pinnedCheckbox'];
  static values = {
    cancelButtonId: String,
    okButtonId: String,
  };

  openModal(event) {
    const { article, pinArticleForm } = event.detail;

    // set the caller checkbox ID
    this.pinArticleForm = pinArticleForm;

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

  changePinnedCheckboxChecked(checked) {
    // find the caller checkbox
    const pinnedCheckbox = this.pinnedCheckboxTargets.find(
      (cb) => cb.id === this.pinnedCheckboxIdValue,
    );
    pinnedCheckbox.checked = checked;
  }

  unPinAndCloseModal() {
    //this.changePinnedCheckboxChecked(false);
    this.closeModal();
  }

  pinAndCloseModal() {
    this.pinArticleForm.submit();
    //    this.changePinnedCheckboxChecked(true);
    this.closeModal();
  }
}
