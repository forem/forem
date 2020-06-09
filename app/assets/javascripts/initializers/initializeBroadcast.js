/* eslint-disable camelcase */
/**
 * Parses the broadcast object on the document into JSON.
 *
 * @function broadcastData
 */
function broadcastData() {
  const { broadcast = null } = document.body.dataset;

  return JSON.parse(broadcast);
}

/**
 * Inserts the broadcast's HTML into `active-broadcast` element
 * as the first child within the document's body, and only inserts the HTML once.
 *
 * @function initializeBroadcast
 */
function initializeBroadcast() {
  const data = broadcastData();
  if (!data) {
    return;
  }
  const { html, banner_class } = data;
  const el = document.getElementById('active-broadcast');

  if (el.firstElementChild) {
    return; // Only append HTML once, on first render.
  }

  const bannerDiv = `<div class='broadcast-data ${
    banner_class || ''
  }'>${html}</div>`;
  el.insertAdjacentHTML('afterbegin', bannerDiv);
}
/* eslint-enable camelcase */
