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
