import { request } from '@utilities/http';

export const postReactions = async ({
  reactable_type,
  category,
  reactable_id,
}) => {
  const response = await request('/reactions', {
    method: 'POST',
    headers: {
      Accept: 'application/json',
      'X-CSRF-Token': window.csrfToken,
      'Content-Type': 'application/json',
    },
    body: { reactable_type, category, reactable_id },
  });

  return await response.json();
};
