import { validateFileInputs } from '../packs/validateFileInputs';

export function previewArticle(payload, successCb, failureCb) {
  fetch('/articles/preview', {
    method: 'POST',
    headers: {
      Accept: 'application/json',
      'X-CSRF-Token': window.csrfToken,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      article_body: payload,
    }),
    credentials: 'same-origin',
  })
    .then(async (response) => {
      const payload = await response.json();

      if (response.status !== 200) {
        throw payload;
      }

      return payload;
    })
    .then(successCb)
    .catch(failureCb);
}

export function getArticle() {}

function processPayload(payload) {
  const {
    /* eslint-disable no-unused-vars */
    previewShowing,
    helpShowing,
    previewResponse,
    helpHTML,
    imageManagementShowing,
    moreConfigShowing,
    errors,
    /* eslint-enable no-unused-vars */
    ...neededPayload
  } = payload;
  return neededPayload;
}

export function submitArticle({ payload, onSuccess, onError }) {
  const method = payload.id ? 'PUT' : 'POST';
  const url = payload.id ? `/articles/${payload.id}` : '/articles';
  fetch(url, {
    method,
    headers: {
      Accept: 'application/json',
      'X-CSRF-Token': window.csrfToken,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      article: processPayload(payload),
    }),
    credentials: 'same-origin',
  })
    .then((response) => response.json())
    .then((response) => {
      if (response.current_state_path) {
        onSuccess();
        window.location.replace(response.current_state_path);
      } else {
        onError(response);
      }
    })
    .catch(onError);
}

function generateUploadFormdata(payload) {
  const token = window.csrfToken;
  const formData = new FormData();
  formData.append('authenticity_token', token);

  Object.entries(payload.image).forEach(([_, value]) =>
    formData.append('image[]', value),
  );

  return formData;
}

export function generateMainImage({ payload, successCb, failureCb, signal }) {
  fetch('/image_uploads', {
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
