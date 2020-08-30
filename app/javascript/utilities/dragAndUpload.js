import { generateMainImage } from '../article-form/actions';
import { validateFileInputs } from '../packs/validateFileInputs';

export function dragDrop(files, handleImageSuccess, handleImageFailure) {
  if (files.length > 0 && validateFileInputs()) {
    const payload = { image: files };
    generateMainImage(payload, handleImageSuccess, handleImageFailure);
  }
}
