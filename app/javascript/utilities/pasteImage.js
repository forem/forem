import { useEffect, useState } from 'preact/hooks';

/**
 * A custom Preact hook used to attach a catch all for pasting images to a DOM element.
 * @example
 * function SomeComponent(props) {
 *   const { setElement } = usePasteImage({
 *     onPaste: somePasteHandler
 *   });
 *
 *  const someDomRef = useRef(null);
 *
 *  useEffect(() => {
 *    if (someDomRef.current) {
 *      setElement(someDomRef.current);
 *    }
 *  });
 *
 *  return <textarea ref={someDomRef}>I'm a text area</textarea>;
 * };
 *
 * @param {object} props
 * @param {Function} props.onPaste The handler that runs when the paste event is fired.
 */
export function usePasteImage({ onPaste }) {
  const [element, setElement] = useState(null);

  useEffect(() => {
    if (!element) return;

    element.addEventListener('paste', onPaste);

    return () => {
      element.removeEventListener('paste', onPaste);
    };
  }, [element, onPaste]);

  return setElement;
}
