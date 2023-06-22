import { validateFileInputs } from '../../packs/validateFileInputs';

function generateUploadFormdata(image) {
  const token = window.csrfToken;
  const formData = new FormData();
  formData.append('authenticity_token', token);
  formData.append('user[profile_image]', image);
  return formData;
}

export function generateMainImage({ payload, successCb, failureCb, signal }) {
  const image = payload.image[0];
  const { userId } = payload;

  if (image) {
    fetch(`/users/${userId}`, {
      method: 'PUT',
      headers: {
        'X-CSRF-Token': window.csrfToken,
        Accept: 'application/json',
      },
      body: generateUploadFormdata(image),
      credentials: 'same-origin',
      signal,
    })
      .then((response) => response.json())
      .then((json) => {
        if (json.error) {
          throw new Error(json.error);
        }
        return successCb(json.user.profile_image.url);
      })
      .catch((message) => failureCb(message));
  }
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
  userId,
) {
  // Currently only one image is supported for upload.
  if (images.length > 0 && validateFileInputs()) {
    const payload = { image: images, userId };

    handleImageUploading();
    generateMainImage({
      payload,
      successCb: handleImageSuccess,
      failureCb: handleImageFailure,
    });
  }
}
