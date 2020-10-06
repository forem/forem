import { isInViewport } from '../viewport';
import { useGlobalKeyEventListener } from './useGlobalKeyEventListener';

const NAVIGATION_UP_KEY = 'k';
const NAVIGATION_DOWN_KEY = 'j';

const DIRECTIONS = {
  UP: 'up',
  DOWN: 'down',
};

/**
 * Registers global key event listeners for 'j' and 'k' to navigate up and down
 * in a list of items
 *
 * @example
 * import { useGlobalListNavigation } from '../utilities/hooks/useGlobalListNavigation';
 *
 * useGlobalListNavigation(
 *   'article[id=featured-story-marker],article[id^=article-]', // the container
 *   'a[id^=article-link-]', // what should be focused on
 *   'div.paged-stories', // waterfall container
 * );
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
 * @param {string} focusableSelector - The selector for the element that should be focused on inside an item
 * @param {string} [waterfallItemContainerSelector = undefined] - The selector for the waterfall item container if the list uses a waterfall structure at any point
 */
export function useGlobalListNavigation(
  itemContainerSelector,
  focusableSelector,
  waterfallItemContainerSelector = undefined,
) {
  function getNextElement(element) {
    return element.nextSibling;
  }

  function getPreviousElement(element) {
    if (element.previousSibling) {
      return element.previousSibling;
    }
    if (waterfallItemContainerSelector) {
      return element.closest(waterfallItemContainerSelector)?.previousSibling;
    }
    return null;
  }

  function getFirstElement() {
    const elements = document.querySelectorAll(itemContainerSelector);
    return Array.prototype.find.call(elements, isInViewport);
  }

  useGlobalKeyEventListener(
    [NAVIGATION_UP_KEY, NAVIGATION_DOWN_KEY],
    (event) => {
      const direction =
        event.key === NAVIGATION_UP_KEY ? DIRECTIONS.UP : DIRECTIONS.DOWN;

      const closestContainer = document.activeElement?.closest(
        itemContainerSelector,
      );

      const nextContainer = !closestContainer
        ? getFirstElement()
        : direction === DIRECTIONS.UP
        ? getPreviousElement(closestContainer)
        : getNextElement(closestContainer);

      const nextFocusable = nextContainer?.querySelector(focusableSelector);
      if (nextFocusable) {
        nextFocusable.focus();
      }
    },
  );
}
