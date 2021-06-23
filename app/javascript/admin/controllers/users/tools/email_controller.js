import { Controller } from 'stimulus';

// eslint-disable-next-line no-restricted-syntax
export default class EmailController extends Controller {
  static targets = ['verifyEmailOwnership'];

  // This method listens to Rails's Ajax event handlers and dispatches the event to the correct action
  // https://guides.rubyonrails.org/working_with_javascript_in_rails.html#rails-ujs-event-handlers
  ajaxSuccess(event) {
    const { target } = event;

    if (target == this.verifyEmailOwnershipTarget) {
      this.onVerifyEmailOwnership();
    }
  }

  onVerifyEmailOwnership() {
    document.dispatchEvent(
      new CustomEvent('snackbar:add', {
        detail: { message: 'Verification email sent!' },
      }),
    );
  }
}
