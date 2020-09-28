import { useEffect } from 'preact/hooks';

const FOCUSED_TAG_EXCLUDE_LIST = ['INPUT', 'TEXTAREA'];

export const registerGlobalKeyEventListener = (keys, callback) => {
  if (!keys || keys.length === 0 || !callback) {
    return null;
  }

  const eventListener = (event) => {
    const { tagName, classList } = document.activeElement;

    if (
      !keys.includes(event.key) ||
      FOCUSED_TAG_EXCLUDE_LIST.includes(tagName) ||
      classList.contains('input')
    )
      return;

    callback(event);
  };

  window.addEventListener('keydown', eventListener);

  return eventListener;
};

export default (keys, callback) => {
  useEffect(() => {
    const eventListener = registerGlobalKeyEventListener(keys, callback);
    if (eventListener) {
      return () => window.removeEventListener('keydown', eventListener);
    }
  }, [keys, callback]);
};
