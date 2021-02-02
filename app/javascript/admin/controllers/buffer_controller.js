import { Controller } from 'stimulus';

const CONFIRM_BADGE_HTML =
  '<span class="ml-2 badge badge-success">Confirm</span>';
const DISMISS_BADGE_HTML =
  '<span class="ml-2 badge badge-danger">Dismiss</span>';

// eslint-disable-next-line no-restricted-syntax
export default class BufferController extends Controller {
  static classes = ['bgHighlighted', 'borderHighlighted'];
  static targets = ['header', 'bodyText'];

  tagBufferUpdateConfirmed() {
    this.clearPreviousBadge();

    this.headerTarget.innerHTML += CONFIRM_BADGE_HTML;
  }

  tagBufferUpdateDismissed() {
    this.clearPreviousBadge();

    this.headerTarget.innerHTML += DISMISS_BADGE_HTML;
  }

  highlightElement() {
    this.element.classList.add(
      this.bgHighlightedClass,
      this.borderHighlightedClass,
    );
    setTimeout(() => {
      this.element.classList.remove(this.bgHighlightedClass);
    }, 350);
  }

  autosizeBodyText() {
    this.bodyTextTarget.rows = this.bodyTextTarget.value.split(
      /\r\n|\r|\n/,
    ).length;
  }

  clearPreviousBadge() {
    const badge = this.headerTarget.getElementsByClassName('badge')[0];
    if (badge) {
      badge.remove();
    }
  }
}
