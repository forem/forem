import { Controller } from 'stimulus';

// eslint-disable-next-line no-restricted-syntax
export default class EmailController extends Controller {
  static targets = ['verifyEmailOwnership', 'sendEmail'];

  // This method listens to Rails's Ajax event handlers and dispatches the event to the correct action
  // https://guides.rubyonrails.org/working_with_javascript_in_rails.html#rails-ujs-event-handlers
  // It is bound to Stimulus via the server side EmailComponent
  ajaxSuccess(event) {
    const { target } = event;

    let message;
    if (target == this.verifyEmailOwnershipTarget) {
      message = 'Verification email sent!';
    } else if (target == this.sendEmailTarget) {
      message = 'Email sent!';
    }

    document.dispatchEvent(
      new CustomEvent('snackbar:add', { detail: { message } }),
    );
  }
}
