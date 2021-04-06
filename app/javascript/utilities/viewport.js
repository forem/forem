/**
 * Checks if an element is visible in the viewport
 *
 * @example
 * const element = document.getElementById('element');
 * isInViewport({element, allowPartialVisibility = true}); // true or false
 *
 * @param {HTMLElement} element - The HTML element to check
 * @param {number} [offsetTop=0] - Part of the screen to ignore counting from the top
 * @param {boolean} [allowPartialVisibility=false] - A boolean to flip the check between partial or completely visible in the viewport
 * @returns {boolean} isInViewport - true if the element is visible in the viewport
 */
export function isInViewport({
  element,
  offsetTop = 0,
  allowPartialVisibility = false,
}) {
  const boundingRect = element.getBoundingClientRect();
  const clientHeight =
    window.innerHeight || document.documentElement.clientHeight;
  const clientWidth = window.innerWidth || document.documentElement.clientWidth;
  const topIsInViewport =
    boundingRect.top <= clientHeight && boundingRect.top >= offsetTop;
  const rightIsInViewport =
    boundingRect.right >= 0 && boundingRect.right <= clientWidth;
  const bottomIsInViewport =
    boundingRect.bottom >= offsetTop && boundingRect.bottom <= clientHeight;
  const leftIsInViewport =
    boundingRect.left <= clientWidth && boundingRect.left >= 0;
  const topIsOutOfViewport = boundingRect.top <= offsetTop;
  const bottomIsOutOfViewport = boundingRect.bottom >= clientHeight;
  const elementSpansEntireViewport =
    topIsOutOfViewport && bottomIsOutOfViewport;

  if (allowPartialVisibility) {
    return (
      (topIsInViewport || bottomIsInViewport || elementSpansEntireViewport) &&
      (leftIsInViewport || rightIsInViewport)
    );
  }
  return (
    topIsInViewport &&
    bottomIsInViewport &&
    leftIsInViewport &&
    rightIsInViewport
  );
}
