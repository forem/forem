import { isInViewport } from '../viewport';
import useGlobalKeyEventListener from './useGlobalKeyEventListener';

const NAVIGATION_UP_KEYS = ['k', 'ArrowUp'];
const NAVIGATION_DOWN_KEYS = ['j', 'ArrowDown'];
const EVENTFUL_KEYS = ['ArrowUp', 'ArrowDown'];

const DIRECTIONS = {
  UP: 'up',
  DOWN: 'down',
};

export default (
  itemContainerSelector,
  focusableSelector,
  waterfallItemContainerSelector = undefined,
) => {
  const getNextElement = (element) => element.nextSibling;

  const getPreviousElement = (element) =>
    element.previousSibling ||
    (waterfallItemContainerSelector &&
      element.closest(waterfallItemContainerSelector)?.previousSibling);

  const getFirstElement = () => {
    const elements = document.querySelectorAll(itemContainerSelector);
    return Array.prototype.find.call(elements, isInViewport);
  };

  useGlobalKeyEventListener(
    [...NAVIGATION_UP_KEYS, ...NAVIGATION_DOWN_KEYS],
    (event) => {
      const direction = NAVIGATION_UP_KEYS.includes(event.key)
        ? DIRECTIONS.UP
        : DIRECTIONS.DOWN;

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
        if (EVENTFUL_KEYS.includes(event.key)) {
          event.preventDefault();
        }
        nextFocusable.focus();
      }
    },
  );
};
