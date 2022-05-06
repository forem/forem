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
 * @returns {Object} A JSON object with the parsed user data.
 */
export const userData = () => {
  const { user = null } = document.body.dataset;
  return JSON.parse(user);
};
