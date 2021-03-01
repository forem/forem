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

    event.currentTarget
      .closest('.drop-area')
      .classList.remove('drop-area--active');

    const { files } = event.dataTransfer;

    if (files.length > 1) {
      addSnackbarItem({
        message: 'Only one image can be dropped at a time.',
        addCloseButton: true,
      });
      return;
    }

    processImageUpload(files, handleImageSuccess, handleImageFailure);
  };
}

/**
 * Dragover handler for the editor
 *
 * @param {DragEvent} event the drag event.
 */
export function onDragOver(event) {
  event.preventDefault();
  event.currentTarget.closest('.drop-area').classList.add('drop-area--active');
}

/**
 * DragExit handler for the editor
 *
 * @param {DragEvent} event the drag event.
 */
export function onDragExit(event) {
  event.preventDefault();
  event.currentTarget
    .closest('.drop-area')
    .classList.remove('drop-area--active');
}

/**
 * Handler for when image upload fails.
 *
 * @param {Error} error an error
 * @param {string} error.message an error message
 */
export function handleImageFailure({ message }) {
  addSnackbarItem({
    message,
    addCloseButton: true,
  });
}
