import { Controller } from 'stimulus';

export default class BufferController extends Controller {
  static targets = ['header', 'bodyText'];

  tagBufferUpdateConfirmed() {
    this.clearPreviousBadge();

    this.headerTarget.innerHTML +=
      '<span class="ml-2 badge badge-success">Confirm</span>';
  }

  tagBufferUpdateDismissed() {
    this.clearPreviousBadge();

    this.headerTarget.innerHTML +=
      '<span class="ml-2 badge badge-danger">Dismiss</span>';
  }

  highlightElement() {
    this.element.classList.add('bg-highlighted', 'border-highlighted');
    setTimeout(() => {
      this.element.classList.remove('bg-highlighted');
    }, 350);
  }

  autosizeBodyText() {
    this.bodyTextTarget.rows = this.bodyTextTarget.value.split(
      /\r\n|\r|\n/,
    ).length;
  }

  clearPreviousBadge() {
    const badge = this.headerTarget.querySelector('.badge');
    if (badge) {
      badge.remove();
    }
  }

  get bufferUpdateId() {
    return parseInt(this.data.get('id'), 10);
  }

  set bufferUpdateId(value) {
    this.data.set('id', value);
  }
}
