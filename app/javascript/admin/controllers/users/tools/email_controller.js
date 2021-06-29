import { Controller } from 'stimulus';

// eslint-disable-next-line no-restricted-syntax
export default class EmailController extends Controller {
  static targets = ['verifyEmailOwnership', 'sendEmail'];

  // This method listens to Rails's Ajax event `ajax:success`.
  // See https://guides.rubyonrails.org/working_with_javascript_in_rails.html#rails-ujs-event-handlers
  // It is bound to Stimulus via the server side EmailComponent's HTML
  ajaxSuccess(event) {
    const { target } = event;

    let message;
    if (target == this.verifyEmailOwnershipTarget) {
      message = 'Verification email sent!';
    } else if (target == this.sendEmailTarget) {
      message = 'Email sent!';
    }

    // display success info message
    document.dispatchEvent(
      new CustomEvent('snackbar:add', { detail: { message } }),
    );

    // close the panel and go back to the home view
    document.dispatchEvent(new CustomEvent('user:home'));
  }

  // This method listens to Rails's Ajax event `ajax:error`.
  // See https://guides.rubyonrails.org/working_with_javascript_in_rails.html#rails-ujs-event-handlers
  // It is bound to Stimulus via the server side EmailComponent's HTML
  ajaxError(event) {
    const [data, ,] = event.detail;
    const message = data.error || 'An error occurred on the server!';

    document.dispatchEvent(
      new CustomEvent('snackbar:add', {
        detail: { message, addCloseButton: true },
      }),
    );
  }
}
