import PropTypes from 'prop-types';
import { isInViewport } from '../../utilities/viewport';
import { useKeyboardShortcuts } from './useKeyboardShortcuts';

const NAVIGATION_UP_KEY = 'KeyK';
const NAVIGATION_DOWN_KEY = 'KeyJ';

const DIRECTIONS = {
  UP: 'up',
  DOWN: 'down',
};

/**
 * Hook that registers a global key shortcut for 'j' and 'k' to navigate up and down in a list of elements
 *
 * @example
 * useListNavigation(
 *   ".crayons-story",
 *   "a[id^=article-link-]",
 *   "div.paged-stories,div.substories",
 * )
 *
 * Note:
 * To avoid conflicts, only one of these should be called per page.
 *
 * Note on waterfalls:
 * In the next example, the waterfall container would be 'div.paged-stories':
 * <article />
 * <article />
 * <div class="paged-stories">
 *   <!-- level 1 -->
 *   <article />
 *   <article />
 *   <div class="paged-stories">
 *     <!-- level 2 -->
 *     <article />
 *     <article />
 *   </div>
 * </div>
 *
 * @param {string} elementSelector - The selector for the highest level container of an element
 * @param {string} waterfallElementContainerSelector - The selector for the waterfall element container if the list uses a waterfall structure at any point
 */
export function useListNavigation(
  elementSelector,
  waterfallElementContainerSelector,
) {
  function navigateInDirection(direction) {
    navigate(elementSelector, waterfallElementContainerSelector, direction);
  }

  useKeyboardShortcuts({
    [NAVIGATION_UP_KEY]: () => navigateInDirection(DIRECTIONS.UP),
    [NAVIGATION_DOWN_KEY]: () => navigateInDirection(DIRECTIONS.DOWN),
  });
}

/**
 * Calls a hook that registers global key event listeners for 'j' and 'k' to navigate up and down in a list of elements
 *
 * @example
 * <ListNavigation
 *   elementSelector=".crayons-story"
 *   waterfallElementContainerSelector="div.paged-stories,div.substories"
 * />
 *
 * Note:
 * To avoid conflicts, only one of these should be called per page.
 *
 * Note on waterfalls:
 * In the next example, the waterfall container would be 'div.paged-stories':
 * <article />
 * <article />
 * <div class="paged-stories">
 *   <!-- level 1 -->
 *   <article />
 *   <article />
 *   <div class="paged-stories">
 *     <!-- level 2 -->
 *     <article />
 *     <article />
 *   </div>
 * </div>
 *
 * @param {string} elementSelector - The selector for the highest level container of an element
 * @param {string} waterfallElementContainerSelector - The selector for the waterfall element container if the list uses a waterfall structure at any point
 */
export function ListNavigation({
  elementSelector,
  waterfallElementContainerSelector,
}) {
  useListNavigation(elementSelector, waterfallElementContainerSelector);

  return null;
}

ListNavigation.propTypes = {
  elementSelector: PropTypes.string.isRequired,
  waterfallElementContainerSelector: PropTypes.string,
};

/**
 * Focuses on the next/previous element depending on the navigation direction
 *
 * @param {string} elementSelector - The selector for the highest level container of an element
 * @param {string} waterfallElementContainerSelector - The selector for the waterfall element container if the list uses a waterfall structure at any point
 * @param {string} direction - The navigation direction (up or down)
 */
function navigate(
  elementSelector,
  waterfallElementContainerSelector,
  direction,
) {
  const closestElement = document.activeElement?.closest(elementSelector);

  let nextElement;
  if (!closestElement) {
    nextElement = getFirstVisibleElement(elementSelector);
  }
  if (!nextElement) {
    const getElementCallback =
      direction === DIRECTIONS.UP ? getPreviousElement : getNextElement;

    nextElement = getElementCallback(
      closestElement,
      elementSelector,
      waterfallElementContainerSelector,
    );
  }

  if (nextElement) {
    if (!isInViewport(nextElement))
      nextElement.scrollIntoView({
        behavior: 'auto',
        block: 'center',
        inline: 'center',
      });
    nextElement.focus();
  }
}

/**
 * Gets the next element of a list that matches a selector
 *
 * @param {object} element - The current element
 * @param {string} elementSelector - The selector for the highest level container of an element
 * @param {string} waterfallElementContainerSelector - The selector for the waterfall element container if the list uses a waterfall structure at any point
 */
function getNextElement(
  element,
  elementSelector,
  waterfallElementContainerSelector,
) {
  if (!element) {
    return null;
  }

  let sibling = element.nextElementSibling;

  if (
    sibling &&
    !sibling.matches(`${elementSelector},${waterfallElementContainerSelector}`)
  ) {
    sibling = sibling.nextElementSibling;
  }

  if (sibling && !sibling.matches(elementSelector)) {
    return sibling.querySelector(elementSelector);
  }

  return sibling;
}

/**
 * Gets the previous element of a list that matches a selector
 *
 * @param {object} element - The current element
 * @param {string} elementSelector - The selector for the highest level container of an element
 * @param {string} waterfallElementContainerSelector - The selector for the waterfall element container if the list uses a waterfall structure at any point
 */
function getPreviousElement(
  element,
  elementSelector,
  waterfallElementContainerSelector,
) {
  if (!element) {
    return null;
  }

  let sibling = element.previousElementSibling;
  if (!sibling && waterfallElementContainerSelector) {
    // reached the top of a waterfall level
    sibling = element.closest(waterfallElementContainerSelector)
      ?.previousElementSibling;
  }

  if (sibling && !sibling.matches(elementSelector)) {
    return sibling.previousElementSibling;
  }

  return sibling;
}

/**
 * Gets the first visible element that matches a selector
 *
 * @param {string} selector - The CSS selector
 */
function getFirstVisibleElement(selector) {
  const elements = document.querySelectorAll(selector);
  return Array.prototype.find.call(elements, isInViewport);
}
