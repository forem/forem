export const jsonToForm = (data) => {
  const form = new FormData();
  data.forEach((item) => form.append(item.key, item.value));
  return form;
};

export const getContentOfToken = (token) =>
  document.querySelector(`meta[name='${token}']`).content;

export const updateOnboarding = (lastPage) => {
  const csrfToken = getContentOfToken('csrf-token');
  fetch('/onboarding', {
    method: 'PATCH',
    headers: {
      'X-CSRF-Token': csrfToken,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({ user: { last_onboarding_page: lastPage } }),
    credentials: 'same-origin',
  });
};

/**
 * A util function to fetch the user's data from off of the document's body.
 *
 *
 * @returns {Object|null} A JSON object with the parsed user data, or null if unavailable.
 */
export const userData = () => {
  const { user = null } = document.body.dataset;
  if (!user) {
    return null;
  }
  try {
    return JSON.parse(user);
  } catch (error) {
    console.error('Error parsing user data:', error);
    return null;
  }
};
