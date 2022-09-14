import ahoy from 'ahoy.js';
// * Create an ahoy event that will track a click on the
// * passed in element.
// *
// * @param {string} elementId A unique identifier to identify the element that is being tracked
// * @param {string} name The name of the event
// */
export function trackClick(elementId, name) {
  document.getElementById(elementId).addEventListener('click', ({ target }) => {
    // We check for any parent container with a data-tracking-name attribute, as otherwise
    // SVGs inside buttons can cause events to be missed
    const relevantNode = target.closest('[data-tracking-name]');

    if (!relevantNode) {
      // We don't want to track this click
      return;
    }
    ahoy.track(name, {
      page: location.href,
      element: relevantNode.dataset.trackingName,
    });
  });
}
