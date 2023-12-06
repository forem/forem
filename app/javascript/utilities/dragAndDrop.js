import { cloneElement } from 'preact';
import { useEffect, useRef, useState } from 'preact/hooks';

/**
 * A custom Preact hook used to attach drag and drop functionality to a DOM element.
 * @example
 * function SomeComponent(props) {
 *   const { setElement } = useDragAndDrop({
 *     onDrop: someDropHandler,
 *     onDragOver: someDragOverHandler,
 *     onDragExit: someDragExitHandler
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
 * @param {Function} props.onDragOver The handler that runs when the dragover event is fired.
 * @param {Function} props.onDragExit The handler that runs when the dragexit/dragleave events are fired.
 * @param {Function} props.onDrop The handler that runs when the drop event is fired.
 */
export function useDragAndDrop({ onDragOver, onDragExit, onDrop }) {
  const [element, setElement] = useState(null);

  useEffect(() => {
    if (!element) {
      return;
    }

    const noDragAndDropHandler = (event) => event.preventDefault();

    document.addEventListener('dragover', noDragAndDropHandler);
    document.addEventListener('drop', noDragAndDropHandler);

    element.addEventListener('dragover', onDragOver);
    element.addEventListener('dragexit', onDragExit);
    element.addEventListener('dragleave', onDragExit);
    element.addEventListener('dragend', onDragExit);
    element.addEventListener('drop', onDrop);

    return () => {
      document.removeEventListener('dragover', noDragAndDropHandler);
      document.removeEventListener('drop', noDragAndDropHandler);

      element.removeEventListener('dragover', onDragOver);
      element.removeEventListener('dragexit', onDragExit);
      element.removeEventListener('dragleave', onDragExit);
      element.removeEventListener('dragend', onDragExit);
      element.removeEventListener('drop', onDrop);
    };
  }, [element, onDragOver, onDragExit, onDrop]);

  return { setElement };
}

/**
 * Registers drag and drop events for the child element that is wrapped by this component.
 *
 * @example
 * <DragAndDropZone
 *     onDragOver={someDragOverHandler}
 *     onDragExit={someDragExitHandler}
 *     onDrop={someDropHandler}
 *     >
 *    <textarea>I'm a text area</textarea>
 * <DragAndDropZone>
 *
 * @param {object} props
 * @param {JSX.Element} props.children The React element that will register it's DOM counterpart with drag and drop events.
 * @param {Function} props.onDragOver The handler that runs when the dragover event is fired.
 * @param {Function} props.onDragExit The handler that runs when the dragexit/dragleave events are fired.
 * @param {Function} props.onDrop The handler that runs when the drop event is fired.
 */
export function DragAndDropZone({ children, onDragOver, onDragExit, onDrop }) {
  if (!children) {
    throw new Error(
      'The <DragAndDropZone /> component children prop is null or was not specified.',
    );
  }

  const { setElement } = useDragAndDrop({ onDragOver, onDragExit, onDrop });
  const dropZoneRef = useRef(null);

  if (dropZoneRef.current) {
    setElement(dropZoneRef.current);
  }

  return cloneElement(children, {
    ref: dropZoneRef,
  });
}
