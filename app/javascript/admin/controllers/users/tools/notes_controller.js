import { Controller } from 'stimulus';

// eslint-disable-next-line no-restricted-syntax
export default class NotesController extends Controller {
  // This method listens to Rails's Ajax event `ajax:success`.
  // See https://guides.rubyonrails.org/working_with_javascript_in_rails.html#rails-ujs-event-handlers
  // It is bound to Stimulus via the server side EmailsComponent's HTML
  ajaxSuccess(_event) {
    const message = 'Note created!';

    // display success info message
    document.dispatchEvent(
      new CustomEvent('snackbar:add', { detail: { message } }),
    );

    // close the panel and go back to the home view
    document.dispatchEvent(new CustomEvent('user:tools'));
  }

  // This method listens to Rails's Ajax event `ajax:error`.
  // See https://guides.rubyonrails.org/working_with_javascript_in_rails.html#rails-ujs-event-handlers
  // It is bound to Stimulus via the server side EmailsComponent's HTML
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
