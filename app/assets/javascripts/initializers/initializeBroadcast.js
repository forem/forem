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
 * The click handler sets a key in local storage and removes the broadcast
 * element entirely from the DOM.
 *
 * @function addCloseButtonClickHandle
 * @param {string} title The title of the broadcast.
 */
function addCloseButtonClickHandle(title) {
  var closeButton = document.getElementsByClassName(
    'close-announcement-button',
  )[0];
  closeButton.onclick = (e) => {
    localStorage.setItem(camelizedBroadcastKey(title), true);
    document.getElementById('active-broadcast').remove();
  };
}

/**
 * A function to insert the broadcast's HTML into the `active-broadcast` element.
 * Determines what classes to add to the broadcast element,
 * and inserts a close button and adds a click handler to it.
 *
 * Adds a `.broadcast-visible` class to the broadcastElement to make it display.
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

  const closeButton = `<button class="close-announcement-button crayons-btn crayons-btn--icon-rounded crayons-btn--inverted crayons-btn--ghost">
    <svg class="crayons-icon" width="24" height="24" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg"><path d="M12 10.586l4.95-4.95 1.414 1.414-4.95 4.95 4.95 4.95-1.414 1.414-4.95-4.95-4.95 4.95-1.414-1.414 4.95-4.95-4.95-4.95L7.05 5.636l4.95 4.95z" /></svg>
  </button>`;

  broadcastElement.insertAdjacentHTML(
    'afterbegin',
    `<div class='broadcast-data'>${html}</div>${closeButton}`,
  );
  addCloseButtonClickHandle(title);
  broadcastElement.classList.add('broadcast-visible');
}

/**
 * A function to determine if a broadcast should render.
 * Does not render a broadcast in an iframe, or on `/connect` and `/new` routes.
 * Does not render a broadcast if the current user has opted-out,
 * if the broadcast has already been inserted, or if the key for
 * the broadcast's title exists in localStorage.
 *
 * @function initializeBroadcast
 */
function initializeBroadcast() {
  const shouldHideBroadcast = window.location.pathname.match(
    /^(?:\/connect|\/new)/,
  );

  // Iframes will attempt to re-render a broadcast, so we want to explicitly
  // avoid initializing one if we are within `window.frameElement`.
  if (window.frameElement || shouldHideBroadcast) {
    const broadcast = document.getElementById('active-broadcast');

    // Hide the broadcast if it exists and we are on a path where it should be hidden.
    if (broadcast) {
      broadcast.classList.remove('broadcast-visible');
    }
    return;
  }

  const user = userData();
  const data = broadcastData();

  if (user && !user.display_announcements) {
    return;
  }
  if (!data) {
    return;
  }

  const { title } = data;
  if (JSON.parse(localStorage.getItem(camelizedBroadcastKey(title))) === true) {
    return; // Do not render broadcast if previously dismissed by user.
  }

  const el = document.getElementById('active-broadcast');
  if (el.firstElementChild) {
    if (!el.classList.contains('broadcast-visible')) {
      // The articleForm may have hidden the broadcast when
      // it loaded, so we need to explicitly display it again.
      el.classList.toggle('broadcast-visible');
    }

    return; // Only append HTML once, on first render.
  }

  renderBroadcast(el, data);
}
/* eslint-enable camelcase */
