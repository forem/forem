import { isInViewport } from './viewport';
import { initKeyboardShortcuts } from './keyboardShortcuts';

const NAVIGATION_UP_KEY = 'KeyK';
const NAVIGATION_DOWN_KEY = 'KeyJ';

const DIRECTIONS = {
  UP: 'up',
  DOWN: 'down',
};

/**
 * Pure DOM list navigation listener ('j' and 'k' shortcuts) that does not require Preact or hooks.
 *
 * @param {string} itemSelector - The selector for the highest level container of an item
 * @param {string} focusableSelector - The selector for the element that should be focused on
 * @param {string} waterfallItemContainerSelector - The selector for the waterfall item container
 * @returns {Function} Cleanup function to remove the listener
 */
export function initListNavigation(
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

  return initKeyboardShortcuts(
    {
      [NAVIGATION_UP_KEY]: () => navigateInDirection(DIRECTIONS.UP),
      [NAVIGATION_DOWN_KEY]: () => navigateInDirection(DIRECTIONS.DOWN),
    },
    window,
    { timeout: 0 },
  );
}

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
    sibling = element.closest(waterfallItemContainerSelector)
      ?.previousElementSibling;
  }

  if (sibling && !sibling.matches(itemSelector)) {
    return sibling.previousElementSibling;
  }

  return sibling;
}

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
