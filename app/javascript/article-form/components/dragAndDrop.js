import { addSnackbarItem } from '../../Snackbar';
import { processImageUpload } from '../actions';

export function handleImageDrop(handleImageSuccess, handleImageFailure) {
  return function (event) {
    event.preventDefault();
    event.currentTarget.classList.remove('opacity-25');

    const { files } = event.dataTransfer;

    processImageUpload(files, handleImageSuccess, handleImageFailure);
  };
}

// TODO: Speak to design about how the dropzone should look when dragging over.
export function onDragOver(event) {
  event.preventDefault();
  event.currentTarget.classList.add('opacity-25');
}

export function onDragExit(event) {
  event.preventDefault();
  // This for now, but basically undo styles that were added in drag over.
  event.currentTarget.classList.remove('opacity-25');
}

export function handleImageFailure(error) {
  console.error(error);

  addSnackbarItem({
    message: 'Unable to add image. Try again',
    addCloseButton: true,
  });
}
