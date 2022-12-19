import ahoy from 'ahoy.js';

// * Create an ahoy event that will track a click on the
// * passed in element.
// *
// * @param {string} elementId A unique identifier to identify the element that is being tracked
// */
export function trackCommentClicks(elementId) {
  document
    .getElementById(elementId)
    ?.addEventListener('click', ({ target }) => {
      const relevantNode = getTrackingNode(target, '[data-tracking-name]');

      if (relevantNode) {
        ahoy.track('Comment section click', {
          page: location.href,
          element: relevantNode.dataset?.trackingName,
        });
      }
    });
}

// * Create an ahoy event that will track a click on the
// * passed in element.
// *
// * @param {string} elementId A unique identifier to identify the element that is being tracked
// */
export function trackCreateAccountClicks(elementId) {
  document
    .getElementById(elementId)
    ?.addEventListener('click', ({ target }) => {
      const relevantNode = getTrackingNode(target, '[data-tracking-id]');
      if (relevantNode) {
        ahoy.track('Clicked on Create Account', {
          version: 0.1,
          page: location.href,
          source: relevantNode.dataset?.trackingSource,
        });
      }
    });
}

function getTrackingNode(target, trackingElement) {
  // We check for any parent container with a trackingElement attribute, as otherwise
  // SVGs inside buttons can cause events to be missed
  const relevantNode = target.closest(trackingElement);
  return relevantNode;
}
