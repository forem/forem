import { validateFileInputs } from '../../packs/validateFileInputs';

function generateUploadFormdata(payload) {
  const token = window.csrfToken;
  const formData = new FormData();
  formData.append('authenticity_token', token);
  formData.append('image', payload.image);

  // Object.entries(payload.image).forEach(([_, value]) =>
  //   formData.append('image[]', value),
  // );

  return formData;
}

export function generateMainImage({ payload, successCb, failureCb, signal }) {
  fetch('/picture_uploads', {
    method: 'POST',
    headers: {
      'X-CSRF-Token': window.csrfToken,
    },
    body: generateUploadFormdata(payload),
    credentials: 'same-origin',
    signal,
  })
    .then((response) => response.json())
    .then((json) => {
      if (json.error) {
        throw new Error(json.error);
      }
      const { links } = json;
      const { image } = payload;
      return successCb({ links, image });
    })
    .catch((message) => failureCb(message));
}

/**
 * Processes images for upload.
 *
 * @param {FileList} images Images to be uploaded.
 * @param {Function} handleImageSuccess The handler that runs when the image is uploaded successfully.
 * @param {Function} handleImageFailure The handler that runs when the image upload fails.
 */
export function processImageUpload(
  images,
  handleImageUploading,
  handleImageSuccess,
  handleImageFailure,
) {
  // Currently only one image is supported for upload.
  if (images.length > 0 && validateFileInputs()) {
    const payload = { image: images };

    handleImageUploading();
    generateMainImage({
      payload,
      successCb: handleImageSuccess,
      failureCb: handleImageFailure,
    });
  }
}
