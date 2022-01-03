import { Controller } from '@hotwired/stimulus';

// eslint-disable-next-line no-restricted-syntax
export default class AjaxController extends Controller {
  // This method listens to Rails's Ajax event `ajax:success`.
  // See https://guides.rubyonrails.org/working_with_javascript_in_rails.html#rails-ujs-event-handlers
  // It is bound to Stimulus via the server side EmailsComponent's HTML
  success(event) {
    const [data, ,] = event.detail;
    const message = data.result;

    // close the panel and go back to the home view
    document.dispatchEvent(new CustomEvent('user:tools'));

    if (message) {
      // display success info message
      document.dispatchEvent(
        new CustomEvent('snackbar:add', { detail: { message } }),
      );
    }
  }

  // This method listens to Rails's Ajax event `ajax:error`.
  // See https://guides.rubyonrails.org/working_with_javascript_in_rails.html#rails-ujs-event-handlers
  // It is bound to Stimulus via the server side EmailsComponent's HTML
  error(event) {
    const [data, ,] = event.detail;
    const message = data.error || 'An error occurred on the server!';

    document.dispatchEvent(
      new CustomEvent('snackbar:add', {
        detail: { message, addCloseButton: true },
      }),
    );
  }
}
