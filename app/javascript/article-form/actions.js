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
    .then(response => response.json())
    .then(successCb)
    .catch(failureCb);
}

export function getArticle() {}

export function submitArticle(payload, clearStorage, errorCb, failureCb) {
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
      article: payload,
    }),
    credentials: 'same-origin',
  })
    .then(response => response.json())
    .then(response => {
      if (response.current_state_path) {
        clearStorage();
        window.location.replace(response.current_state_path);
      } else {
        errorCb(response);
      }
    })
    .catch(failureCb);
}

function generateUploadFormdata(payload) {
  const token = window.csrfToken;
  const formData = new FormData();
  formData.append('authenticity_token', token);
  formData.append('image', payload.image[0]);
  if (payload.wrap_cloudinary) {
    formData.append('wrap_cloudinary', 'true');
  }
  return formData;
}

export function generateMainImage(payload, successCb, failureCb) {
  fetch('/image_uploads', {
    method: 'POST',
    headers: {
      'X-CSRF-Token': window.csrfToken,
    },
    body: generateUploadFormdata(payload),
    credentials: 'same-origin',
  })
    .then(response => response.json())
    .then(json => {
      if (json.error) {
        throw new Error(json.error);
      }

      return successCb(json);
    })
    .catch(failureCb);
}
