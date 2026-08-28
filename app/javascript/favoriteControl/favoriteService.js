import { request } from '@utilities/http';

/**
 * Make the given Article or Comment a favorite.
 *
 * @param {object} params
 * @param {number|string} params.favoritableId
 * @param {string} params.favoritableType 'Article' or 'Comment'
 *
 * @returns {Promise<Response>} the raw response
 */
export function makeFavorite({ favoritableId, favoritableType }) {
  return request('/favorites', {
    method: 'POST',
    headers: {
      Accept: 'application/json',
      'Content-Type': 'application/json',
    },
    body: {
      favoritable_id: favoritableId,
      favoritable_type: favoritableType,
    },
  });
}
