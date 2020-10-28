import { h, render } from 'preact';
import { addSnackbarItem, Snackbar } from './Snackbar/Snackbar';

const dayOfWeek = new Date().getDay();

// We only want to disable mouse usage
// on Fridays.
if (dayOfWeek === 5) {
  import('no-mouse-days').then((_data) => {
    const snackZone = document.getElementById('snack-zone');

    if (!snackZone.firstElementChild) {
      // only render the Snackbar if it has been rendered yet.
      render(<Snackbar lifespan="3" />, snackZone);
    }

    addSnackbarItem({
      message: `Welcome to no mouse Fridays.`,
      addCloseButton: true,
    });
  });
}
