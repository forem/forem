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

/**
 * Handler for when image is pasted.
 *
 * @param {function} handleImageSuccess Callback for when image upload succeeds
 * @param {function} handleImageFailure Callback for when image upload fails
 */
export function handleImagePasted(handleImageSuccess, handleImageFailure) {
  return function (event) {
    if (!event.clipboardData || !event.clipboardData.items) return;
    if (!matchesDataTransferType(event.clipboardData.types)) return;

    event.preventDefault();

    const { files } = event.clipboardData;

    if (files.length > 1) {
      addSnackbarItem({
        message: 'Only one image can be pasted at a time.',
        addCloseButton: true,
      });
      return;
    }

    processImageUpload(files, handleImageSuccess, handleImageFailure);
  };
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
