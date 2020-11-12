/**
 * Checks if an element is visible in the viewport
 *
 * @example
 * const element = document.querySelector('#element');
 * isInViewport(element); // true or false
 *
 * @param {object} element - The HTML element to check
 * @param {number} [offsetTop=0] - Part of the screen to ignore counting from the top
 *
 * @returns {boolean} isInViewport - true if the element is visible in the viewport
 */
export function isInViewport(element, offsetTop = 0) {
  const boundingRect = element.getBoundingClientRect();
  const clientHeight =
    window.innerHeight || document.documentElement.clientHeight;
  const clientWidth = window.innerWidth || document.documentElement.clientWidth;
  return (
    boundingRect.top >= offsetTop &&
    boundingRect.left >= 0 &&
    boundingRect.bottom <= clientHeight &&
    boundingRect.right <= clientWidth
  );
}
