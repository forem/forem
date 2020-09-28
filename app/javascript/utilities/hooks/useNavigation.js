import { isInViewport } from '../viewport';
import useKeyEventListener from './useKeyEventListener';

const NAVIGATION_UP_KEYS = ['k', 'ArrowUp'];
const NAVIGATION_DOWN_KEYS = ['j', 'ArrowDown'];
const EVENTFUL_KEYS = ['ArrowUp', 'ArrowDown'];

const useNavigation = (
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

  useKeyEventListener(
    [...NAVIGATION_UP_KEYS, ...NAVIGATION_DOWN_KEYS],
    (event) => {
      const direction = NAVIGATION_UP_KEYS.includes(event.key) ? 'up' : 'down';

      let closestContainer = document.activeElement?.closest(
        itemContainerSelector,
      );

      let nextContainer = !closestContainer
        ? getFirstElement()
        : direction === 'up'
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

export default useNavigation;
