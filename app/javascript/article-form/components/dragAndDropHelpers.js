import { addSnackbarItem } from '../../Snackbar';
import { processImageUpload } from '../actions';

/**
 * Determines if at least one type of drag and drop datum type matches the data transfer type to match.
 *
 * @param {string[]} types An array of data transfer types.
 * @param {string} dataTransferType The data transfer type to match.
 */
export function matchesDataTransferType(
  types = [],
  dataTransferType = 'Files',
) {
  return types.some((type) => type === dataTransferType);
}

// TODO: Document functions
export function handleImageDrop(handleImageSuccess, handleImageFailure) {
  return function (event) {
    event.preventDefault();

    if (!matchesDataTransferType(event.dataTransfer.types)) {
      return;
    }

    event.currentTarget.classList.remove('opacity-25');

    const { files } = event.dataTransfer;

    processImageUpload(files, handleImageSuccess, handleImageFailure);
  };
}

export function onDragOver(event) {
  event.preventDefault();
  event.currentTarget.classList.add('opacity-25');
}

export function onDragExit(event) {
  event.preventDefault();
  event.currentTarget.classList.remove('opacity-25');
}

export function handleImageFailure({ message }) {
  addSnackbarItem({
    message,
    addCloseButton: true,
  });
}
