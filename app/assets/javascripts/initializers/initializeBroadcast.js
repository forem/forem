/* eslint-disable camelcase */
/**
 * Parses the broadcast object on the document into JSON.
 *
 * @function broadcastData
 * @returns {Object} Returns an object of the parsed broadcast data.
 */
function broadcastData() {
  const { broadcast = null } = document.body.dataset;

  return JSON.parse(broadcast);
}

/**
 * Parses the broadcast object on the document into JSON.
 *
 * @function camelizedBroadcastKey
 * @param {string} title The title of the broadcast.
 * @returns {string} Returns the camelized title appended with "Seen".
 */
function camelizedBroadcastKey(title) {
  const camelizedTitle = title.replace(/\W+(.)/g, (match, string) => {
    return string.toUpperCase();
  });

  return `${camelizedTitle}Seen`;
}

/**
 * A function that finds the close button and adds a click handler to it.
 *
 * @function addCloseButtonClickHandle
 * @param {string} title The title of the broadcast.
 */
function addCloseButtonClickHandle(title) {
  var closeButton = document.getElementsByClassName(
    'close-announcement-button',
  )[0];
  closeButton.onclick = (e) => {
    document.getElementById('active-broadcast').style.display = 'none';
    localStorage.setItem(camelizedBroadcastKey(title), true);
  };
}

/**
 * A function to insert the broadcast's HTML into the `active-broadcast` element.
 * Determines what classes to add to the broadcast element,
 * and inserts a close button and adds a click handler to it.
 *
 * Adds a `.visible` class to the broadcastElement to make it render.
 *
 * @function initializeBroadcast
 * @param {string} broadcastElement The HTML element for the broadcast, with a class of `.active-broadcast`.
 * @param {Object} data An object representing the parsed broadcast data.
 */
function renderBroadcast(broadcastElement, data) {
  const { banner_class, html, title } = data;

  if (banner_class) {
    const [defaultClass, additionalClass] = banner_class.split(' ');
    if (additionalClass) {
      broadcastElement.classList.add(defaultClass, additionalClass);
    } else {
      broadcastElement.classList.add(defaultClass);
    }
  }

  const closeButton = `<button class="close-announcement-button">
    <svg width="14" height="14" viewBox="0 0 14 14" fill="none" xmlns="http://www.w3.org/2000/svg">
      <path d="M6.99974 5.58623L11.9497 0.63623L13.3637 2.05023L8.41374 7.00023L13.3637 11.9502L11.9497 13.3642L6.99974 8.41423L2.04974 13.3642L0.635742 11.9502L5.58574 7.00023L0.635742 2.05023L2.04974 0.63623L6.99974 5.58623Z" fill="white" />
    </svg>
  </button>`;

  broadcastElement.insertAdjacentHTML(
    'afterbegin',
    `<div class='broadcast-data'>${html}</div>${closeButton}`,
  );
  addCloseButtonClickHandle(title);
  broadcastElement.classList.add('visible');
}

/**
 * A function to determine if a broadcast should render
 * Does not render broadcast it has already been inserted,
 * or if the key for the broadcast's title exists in localStorage.
 *
 * @function initializeBroadcast
 */
function initializeBroadcast() {
  const data = broadcastData();
  if (!data) {
    return;
  }

  const { title } = data;
  if (JSON.parse(localStorage.getItem(camelizedBroadcastKey(title))) === true) {
    return; // Do not render broadcast if previously dismissed by user.
  }

  const el = document.getElementById('active-broadcast');
  if (el.firstElementChild) {
    return; // Only append HTML once, on first render.
  }

  renderBroadcast(el, data);
}
/* eslint-enable camelcase */
