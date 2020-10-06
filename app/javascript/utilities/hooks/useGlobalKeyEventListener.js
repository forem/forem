import { useEffect } from 'preact/hooks';

const FOCUSED_TAG_EXCLUDE_LIST = ['INPUT', 'TEXTAREA'];

/**
 * Registers a key event listener to the window
 *
 * @example
 * import { registerGlobalKeyEventListener } from '../utilities/hooks/useGlobalKeyEventListener';
 *
 * componentDidMount() {
 *   this.globalKeyEventListener = registerGlobalKeyEventListener(
 *     ['j', 'k'],
 *     function(event) {
 *       // do something
 *     }
 *   )
 * }
 *
 * componentDidUnmount() {
 *   document.removeEventListener('keydown', this.globalKeyEventListener);
 * }
 *
 * Note:
 * This function is used by class-based components. The
 * registered event listener is returned so that it can
 * be unregistered manually on component unmount. For
 * functional components, use the useGlobalKeyEventListener
 * hook below which takes care of of the unregistering
 * automatically.
 *
 * @param {string[]} keys The keys that should be listened to
 * @param {function(object)} callback The function that should be called when one of the keys is pressed
 *
 * @returns {function(event)} eventListener The registered event listener
 */
export function registerGlobalKeyEventListener(keys, callback) {
  if (!keys || keys.length === 0 || !callback) {
    return null;
  }

  function eventListener(event) {
    const { tagName, classList } = document.activeElement;

    if (
      !keys.includes(event.key) ||
      FOCUSED_TAG_EXCLUDE_LIST.includes(tagName) ||
      classList.contains('input')
    ) {
      return;
    }

    callback(event);
  }

  window.addEventListener('keydown', eventListener);

  return eventListener;
}

/**
 * Hook to register a key event listener to the window
 *
 * @example import { useGlobalKeyEventListener } from './useGlobalKeyEventListener';
 *
 * useGlobalKeyEventListener(
 *   ['j', 'k'],
 *   function(event) {
 *     // do something
 *   }
 * );
 *
 * Note: The hook unregisters the event listener automatically when the component unmounts
 *
 * @param {string[]} keys The keys that should be listened to
 * @param {function(object)} callback The function that should be called when
 * one of the keys is pressed
 */
export function useGlobalKeyEventListener(keys, callback) {
  useEffect(() => {
    const eventListener = registerGlobalKeyEventListener(keys, callback);
    if (eventListener) {
      return () => window.removeEventListener('keydown', eventListener);
    }
  }, [keys, callback]);
}
