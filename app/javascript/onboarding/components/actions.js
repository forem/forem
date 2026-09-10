import { locale } from '@utilities/locale';

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
      .then(async (response) => {
        const text = await response.text();
        let json;
        try {
          json = text ? JSON.parse(text) : {};
        } catch (e) {
          throw new Error(locale('image_uploads_controller.server_error') || 'A server error has occurred!');
        }
        if (!response.ok) {
           throw new Error(json.error || locale('image_uploads_controller.server_error') || 'A server error has occurred!');
        }
        if (json.error) {
          throw new Error(json.error);
        }
        return json;
      })
      .then((json) => {
        return successCb(json.user.profile_image.url);
      })
      .catch((error) => {
        const message = error instanceof Error ? error.message : String(error);
        failureCb(message);
      });
  }
}
