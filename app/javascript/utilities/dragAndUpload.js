import { generateMainImage } from '../article-form/actions';
import { validateFileInputs } from '../packs/validateFileInputs';

export function dragDrop(e, handleImageSuccess, handleImageFailure) {
  e.preventDefault();
  const files = e.dataTransfer.files;

  if (files.length > 0 && validateFileInputs()) {
    const payload = { image: files };
    generateMainImage(payload, handleImageSuccess, handleImageFailure);
  }
}
