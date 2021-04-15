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
 * Hook that registers a global key shortcut for 'j' and 'k' to navigate up and down in a list of items
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
 * @param {string} itemSelector - The selector for the highest level container of an item
 * @param {string} focusableSelector - The selector for the element that should be focused on
 * @param {string} waterfallItemContainerSelector - The selector for the waterfall item container if the list uses a waterfall structure at any point
 */
export function useListNavigation(
  itemSelector,
  focusableSelector,
  waterfallItemContainerSelector,
) {
  function navigateInDirection(direction) {
    navigate(
      itemSelector,
      focusableSelector,
      waterfallItemContainerSelector,
      direction,
    );
  }

  useKeyboardShortcuts(
    {
      [NAVIGATION_UP_KEY]: () => navigateInDirection(DIRECTIONS.UP),
      [NAVIGATION_DOWN_KEY]: () => navigateInDirection(DIRECTIONS.DOWN),
    },
    window,
    { timeout: 0 },
  );
}

/**
 * Calls a hook that registers global key event listeners for 'j' and 'k' to navigate up and down in a list of items
 *
 * @example
 * <ListNavigation
 *   itemSelector=".crayons-story"
 *   focusableSelector="a[id^=article-link-]"
 *   waterfallItemContainerSelector="div.paged-stories,div.substories"
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
 * @param {string} itemSelector - The selector for the highest level container of an item
 * @param {string} focusableSelector - The selector for the element that should be focused on
 * @param {string} waterfallItemContainerSelector - The selector for the waterfall item container if the list uses a waterfall structure at any point
 */
export function ListNavigation({
  itemSelector,
  focusableSelector,
  waterfallItemContainerSelector,
}) {
  useListNavigation(
    itemSelector,
    focusableSelector,
    waterfallItemContainerSelector,
  );

  return null;
}

ListNavigation.propTypes = {
  itemSelector: PropTypes.string.isRequired,
  focusableSelector: PropTypes.string.isRequired,
  waterfallItemContainerSelector: PropTypes.string,
};

/**
 * Focuses on the next/previous element depending on the navigation direction
 *
 * @param {string} itemSelector - The selector for the highest level container of an item
 * @param {string} focusableSelector - The selector for the element that should be focused on
 * @param {string} waterfallItemContainerSelector - The selector for the waterfall item container if the list uses a waterfall structure at any point
 * @param {string} direction - The navigation direction (up or down)
 */
function navigate(
  itemSelector,
  focusableSelector,
  waterfallItemContainerSelector,
  direction,
) {
  const closestContainer = document.activeElement?.closest(itemSelector);

  let nextContainer;
  if (!closestContainer) {
    nextContainer = getFirstVisibleElement(itemSelector);
  }
  if (!nextContainer) {
    const getElementCallback =
      direction === DIRECTIONS.UP ? getPreviousElement : getNextElement;

    nextContainer = getElementCallback(
      closestContainer,
      itemSelector,
      waterfallItemContainerSelector,
    );
  }

  const nextFocusable = nextContainer?.querySelector(focusableSelector);
  if (nextFocusable) {
    nextFocusable.focus();
    if (!isInViewport({ element: nextFocusable, offsetTop: 64 })) {
      window.scrollTo({ top: nextContainer.offsetTop - 64 });
    }
  }
}

/**
 * Gets the next element of a list that matches a selector
 *
 * @param {object} element - The current element
 * @param {string} itemSelector - The selector for the highest level container of an item
 * @param {string} waterfallItemContainerSelector - The selector for the waterfall item container if the list uses a waterfall structure at any point
 *
 * @returns {object} The next element to focus on
 */
function getNextElement(element, itemSelector, waterfallItemContainerSelector) {
  const sibling = element?.nextElementSibling;
  if (
    sibling &&
    !sibling.matches(`${itemSelector},${waterfallItemContainerSelector}`)
  ) {
    return sibling.nextElementSibling;
  }
  return sibling;
}

/**
 * Gets the previous element of a list that matches a selector
 *
 * @param {object} element - The current element
 * @param {string} itemSelector - The selector for the highest level container of an item
 * @param {string} waterfallItemContainerSelector - The selector for the waterfall item container if the list uses a waterfall structure at any point
 *
 * @returns {object} The previous element to focus on
 */
function getPreviousElement(
  element,
  itemSelector,
  waterfallItemContainerSelector,
) {
  if (!element) {
    return null;
  }

  let sibling = element.previousElementSibling;
  if (!sibling && waterfallItemContainerSelector) {
    // reached the top of a waterfall level
    sibling = element.closest(waterfallItemContainerSelector)
      ?.previousElementSibling;
  }

  if (sibling && !sibling.matches(itemSelector)) {
    return sibling.previousElementSibling;
  }

  return sibling;
}

/**
 * Checks if the first completely visible element is present that matches a selector and returns if it is available
 * If that isn't visible, it looks for the partially visible element that is present and returns that
 * If no elements visible(like the banner case which could cover the entire viewport), we select the first element from the list
 *
 * @param {string} selector - The CSS selector
 *
 * @returns {object} The first visible element
 */
function getFirstVisibleElement(selector) {
  const elements = [...document.querySelectorAll(selector)];
  const completelyVisibleFirstElement = elements.find((element) =>
    isInViewport({ element }),
  );
  if (completelyVisibleFirstElement) {
    return completelyVisibleFirstElement;
  }
  const partiallyVisibleFirstElement = elements.find((element) =>
    isInViewport({ element, allowPartialVisibility: true }),
  );
  if (partiallyVisibleFirstElement) {
    return partiallyVisibleFirstElement;
  }
  return elements[0];
}
