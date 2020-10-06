import { isInViewport } from '../viewport';
import useGlobalKeyEventListener from './useGlobalKeyEventListener';

const NAVIGATION_UP_KEY = 'k';
const NAVIGATION_DOWN_KEY = 'j';

const DIRECTIONS = {
  UP: 'up',
  DOWN: 'down',
};

export default (
  itemContainerSelector,
  focusableSelector,
  waterfallItemContainerSelector = undefined,
) => {
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
};
