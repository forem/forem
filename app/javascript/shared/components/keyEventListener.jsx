import { useEffect } from 'preact/hooks';
import PropTypes from 'prop-types';

const FOCUSED_TAG_EXCLUDE_LIST = ['INPUT', 'TEXTAREA'];

/**
 * Calls a hook that registers a key event listener to the window
 *
 * <KeyEventListener
 *   keys=['j', 'k']
 *   onPress={(event) => {
 *     // navigate
 *   }}
 * />
 */
export function KeyEventListener({ keys, onPress }) {
  useGlobalKeyEventListener(keys, onPress);

  return null;
}

KeyEventListener.propTypes = {
  keys: PropTypes.arrayOf(PropTypes.string).isRequired,
  onPress: PropTypes.func.isRequired,
};

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

function registerGlobalKeyEventListener(keys, callback) {
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
