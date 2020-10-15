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
 * @param {string} itemContainerSelector - The selector for the highest level container of an item
 * @param {string} focusableSelector - The selector for the element that should be focused on
 * @param {string} waterfallItemContainerSelector - The selector for the waterfall item container if the list uses a waterfall structure at any point
 */
export function useListNavigation(
  itemContainerSelector,
  focusableSelector,
  waterfallItemContainerSelector,
) {
  useKeyboardShortcuts({
    [NAVIGATION_UP_KEY]: () =>
      keyEventListener(
        itemContainerSelector,
        focusableSelector,
        waterfallItemContainerSelector,
        DIRECTIONS.UP,
      ),
    [NAVIGATION_DOWN_KEY]: () =>
      keyEventListener(
        itemContainerSelector,
        focusableSelector,
        waterfallItemContainerSelector,
        DIRECTIONS.DOWN,
      ),
  });
}

/**
 * Calls a hook that registers global key event listeners for 'j' and 'k' to navigate up and down in a list of items
 *
 * @example
 * <ListNavigation
 *   itemContainerSelector=".crayons-story"
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
 * @param {string} itemContainerSelector - The selector for the highest level container of an item
 * @param {string} focusableSelector - The selector for the element that should be focused on
 * @param {string} waterfallItemContainerSelector - The selector for the waterfall item container if the list uses a waterfall structure at any point
 */
export function ListNavigation({
  itemContainerSelector,
  focusableSelector,
  waterfallItemContainerSelector,
}) {
  useListNavigation(
    itemContainerSelector,
    focusableSelector,
    waterfallItemContainerSelector,
  );

  return null;
}

ListNavigation.propTypes = {
  itemContainerSelector: PropTypes.string.isRequired,
  focusableSelector: PropTypes.string.isRequired,
  waterfallItemContainerSelector: PropTypes.string,
};

/**
 * Focuses on the next/previous element depending on the navigation direction
 *
 * @param {string} itemContainerSelector - The selector for the highest level container of an item
 * @param {string} focusableSelector - The selector for the element that should be focused on
 * @param {string} waterfallItemContainerSelector - The selector for the waterfall item container if the list uses a waterfall structure at any point
 * @param {string} direction - The navigation direction (up or down)
 */
function keyEventListener(
  itemContainerSelector,
  focusableSelector,
  waterfallItemContainerSelector,
  direction,
) {
  const closestContainer = document.activeElement?.closest(
    itemContainerSelector,
  );

  let nextContainer;
  if (!closestContainer) {
    nextContainer = getFirstVisibleElement(itemContainerSelector);
  }
  if (!nextContainer) {
    nextContainer =
      direction === DIRECTIONS.UP
        ? getPreviousElement(
            closestContainer,
            itemContainerSelector,
            waterfallItemContainerSelector,
          )
        : getNextElement(
            closestContainer,
            itemContainerSelector,
            waterfallItemContainerSelector,
          );
  }

  const nextFocusable = nextContainer?.querySelector(focusableSelector);
  if (nextFocusable) {
    nextFocusable.focus();
  }
}

/**
 * Gets the next element of a list that matches a selector
 *
 * @param {object} element - The current element
 * @param {string} itemContainerSelector - The selector for the highest level container of an item
 * @param {string} waterfallItemContainerSelector - The selector for the waterfall item container if the list uses a waterfall structure at any point
 */
function getNextElement(
  element,
  itemContainerSelector,
  waterfallItemContainerSelector,
) {
  const sibling = element?.nextElementSibling;
  if (
    sibling &&
    !sibling.matches(
      `${itemContainerSelector},${waterfallItemContainerSelector}`,
    )
  ) {
    return sibling.nextElementSibling;
  }
  return sibling;
}

/**
 * Gets the previous element of a list that matches a selector
 *
 * @param {object} element - The current element
 * @param {string} itemContainerSelector - The selector for the highest level container of an item
 * @param {string} waterfallItemContainerSelector - The selector for the waterfall item container if the list uses a waterfall structure at any point
 */
function getPreviousElement(
  element,
  itemContainerSelector,
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

  if (sibling && !sibling.matches(itemContainerSelector)) {
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
