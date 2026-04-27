const DEFAULT_PROFILE_IMAGE_UPLOAD_ERROR =
  'Unable to upload profile image. Please try again.';

function getCsrfToken() {
  return (
    document
      .querySelector('meta[name="csrf-token"]')
      ?.getAttribute('content') || window.csrfToken
  );
}

function generateUploadFormdata(image, token) {
  const formData = new FormData();
  formData.append('authenticity_token', token);
  formData.append('user[profile_image]', image);
  return formData;
}

async function parseUploadResponse(response) {
  const text = await response.text();

  if (!text) {
    return {};
  }

  try {
    return JSON.parse(text);
  } catch {
    throw new Error(DEFAULT_PROFILE_IMAGE_UPLOAD_ERROR);
  }
}

function normalizeUploadError(error) {
  if (error instanceof Error) {
    return error;
  }

  return new Error(error?.message || DEFAULT_PROFILE_IMAGE_UPLOAD_ERROR);
}

export function generateMainImage({ payload, successCb, failureCb, signal }) {
  const image = payload.image[0];
  const { userId } = payload;

  if (image) {
    const csrfToken = getCsrfToken();

    fetch(`/users/${userId}`, {
      method: 'PUT',
      headers: {
        'X-CSRF-Token': csrfToken,
        Accept: 'application/json',
      },
      body: generateUploadFormdata(image, csrfToken),
      credentials: 'same-origin',
      signal,
    })
      .then(async (response) => {
        const json = await parseUploadResponse(response);

        if (!response.ok) {
          throw new Error(json.error || DEFAULT_PROFILE_IMAGE_UPLOAD_ERROR);
        }

        return json;
      })
      .then((json) => {
        if (json.error) {
          throw new Error(json.error);
        }

        if (!json.user?.profile_image?.url) {
          throw new Error(DEFAULT_PROFILE_IMAGE_UPLOAD_ERROR);
        }

        return successCb(json.user.profile_image.url);
      })
      .catch((message) => failureCb(normalizeUploadError(message)));
  }
}
