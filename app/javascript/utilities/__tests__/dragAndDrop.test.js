import { h } from 'preact';
import { render } from '@testing-library/preact';
import { renderHook, act } from '@testing-library/preact-hooks';
import { DragAndDropZone, useDragAndDrop } from '@utilities/dragAndDrop';

describe('drag and drop for components', () => {
  describe('useDragAndDrop', () => {
    it('should not add drag and drop event listeners when DOM element is null', () => {
      const onDrop = jest.fn();
      const onDragOver = jest.fn();
      const onDragExit = jest.fn();

      HTMLElement.prototype.addEventListener = jest.fn();
      HTMLDocument.prototype.addEventListener = jest.fn();

      const { result } = renderHook(() =>
        useDragAndDrop({
          onDrop,
          onDragOver,
          onDragExit,
        }),
      );

      act(() => {
        result.current.setElement(null);
      });

      expect(HTMLElement.prototype.addEventListener).not.toHaveBeenCalled();
      expect(HTMLDocument.prototype.addEventListener).not.toHaveBeenCalled();
    });

    it('should attach drag and drop events when setElement receives a DOM node', () => {
      const onDrop = jest.fn();
      const onDragOver = jest.fn();
      const onDragExit = jest.fn();

      HTMLElement.prototype.addEventListener = jest.fn();
      HTMLDocument.prototype.addEventListener = jest.fn();

      const { result } = renderHook(() =>
        useDragAndDrop({
          onDrop,
          onDragOver,
          onDragExit,
        }),
      );

      act(() => {
        result.current.setElement(document.createElement('textarea'));
      });

      expect(HTMLElement.prototype.addEventListener).toHaveBeenCalledTimes(5);
      expect(HTMLDocument.prototype.addEventListener).toHaveBeenCalledTimes(2);
    });

    it('should remove drag and drop event listeners when the hook is unmounted', () => {
      const onDrop = jest.fn();
      const onDragOver = jest.fn();
      const onDragExit = jest.fn();

      HTMLElement.prototype.removeEventListener = jest.fn();
      HTMLDocument.prototype.removeEventListener = jest.fn();

      const { unmount, result } = renderHook(() =>
        useDragAndDrop({
          onDrop,
          onDragOver,
          onDragExit,
        }),
      );

      act(() => {
        result.current.setElement(document.createElement('textarea'));
      });

      unmount();
      expect(HTMLDocument.prototype.removeEventListener).toHaveBeenCalledTimes(
        2,
      );
      expect(HTMLElement.prototype.removeEventListener).toHaveBeenCalledTimes(
        5,
      );
    });
  });

  describe('<DragAndDropZone />', () => {
    it('should attach drag and drop events', async () => {
      const onDrop = jest.fn();
      const onDragOver = jest.fn();
      const onDragExit = jest.fn();

      HTMLElement.prototype.addEventListener = jest.fn();
      HTMLDocument.prototype.addEventListener = jest.fn();

      const { rerender } = render(
        <DragAndDropZone
          onDragOver={onDragOver}
          onDragExit={onDragExit}
          onDrop={onDrop}
        >
          <textarea>I'm a text area</textarea>
        </DragAndDropZone>,
      );

      // Rerendering so that the ref gets set to the DOM node.
      // represented by the Preact element <textarea />
      rerender(
        <DragAndDropZone
          onDragOver={onDragOver}
          onDragExit={onDragExit}
          onDrop={onDrop}
        >
          <textarea>I'm a text area</textarea>
        </DragAndDropZone>,
      );

      expect(HTMLDocument.prototype.addEventListener).toBeCalledTimes(2);
      expect(HTMLElement.prototype.addEventListener).toHaveBeenCalledTimes(5);
    });

    it('should not attach drag and drop events', async () => {
      const onDrop = jest.fn();
      const onDragOver = jest.fn();
      const onDragExit = jest.fn();

      HTMLElement.prototype.removeEventListener = jest.fn();
      HTMLDocument.prototype.removeEventListener = jest.fn();

      const { unmount, rerender } = render(
        <DragAndDropZone
          onDragOver={onDragOver}
          onDragExit={onDragExit}
          onDrop={onDrop}
        >
          <textarea>I'm a text area</textarea>
        </DragAndDropZone>,
      );

      // Rerendering so that the ref gets set to the DOM node.
      // represented by the Preact element <textarea />
      rerender(
        <DragAndDropZone
          onDragOver={onDragOver}
          onDragExit={onDragExit}
          onDrop={onDrop}
        >
          <textarea>I'm a text area</textarea>
        </DragAndDropZone>,
      );

      unmount();
      expect(HTMLDocument.prototype.removeEventListener).toBeCalledTimes(2);
      expect(HTMLElement.prototype.removeEventListener).toHaveBeenCalledTimes(
        5,
      );
    });

    it('should not attach drag and drop events when no children.', async () => {
      const onDrop = jest.fn();
      const onDragOver = jest.fn();
      const onDragExit = jest.fn();

      HTMLElement.prototype.addEventListener = jest.fn();
      HTMLDocument.prototype.addEventListener = jest.fn();

      expect(() => {
        render(
          <DragAndDropZone
            onDragOver={onDragOver}
            onDragExit={onDragExit}
            onDrop={onDrop}
          />,
        );
      }).toThrowError(
        'The <DragAndDropZone /> component children prop is null or was not specified.',
      );
    });
  });
});
