import { useEffect } from 'preact/hooks';

const useKeyEventListener = (keys, callback) => {
  useEffect(() => {
    const eventListener = () => {
      const { tagName, classList } = document.activeElement;

      if (
        !keys.includes(event.key) ||
        tagName === 'INPUT' ||
        tagName === 'TEXTAREA' ||
        classList.contains('input')
      )
        return;

      callback(event);
    };

    if ((keys || []).length > 0 && callback) {
      window.addEventListener('keydown', eventListener);
      return () => window.removeEventListener('keydown', eventListener);
    }
  }, [keys, callback]);
};

export default useKeyEventListener;
