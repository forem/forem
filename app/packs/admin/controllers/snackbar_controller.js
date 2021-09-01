import { Controller } from 'stimulus';

// Wraps the Preact Snackbar component into a Stimulus controller
export default class SnackbarController extends Controller {
  static targets = ['snackZone'];

  async connect() {
    const [{ h, render }, { Snackbar }] = await Promise.all([
      import('preact'),
      // eslint-disable-next-line import/no-unresolved
      import('Snackbar'),
    ]);

    render(<Snackbar lifespan="3" />, this.snackZoneTarget);
  }

  async disconnect() {
    const { render } = await import('preact');
    render(null, this.snackZoneTarget);
  }

  // Any Stimulus controller can add an item to the Snackbar by dispatching a custom event
  // data-action="snackbar:add@document->snackbar#addItem"
  async addItem(event) {
    const { message, addCloseButton = false } = event.detail;

    // eslint-disable-next-line import/no-unresolved
    const { addSnackbarItem } = await import('Snackbar');
    addSnackbarItem({ message, addCloseButton });
  }
}
