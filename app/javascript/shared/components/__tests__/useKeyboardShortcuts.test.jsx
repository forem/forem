import { h } from 'preact';
import { renderHook } from '@testing-library/preact-hooks';
import { fireEvent, render } from '@testing-library/preact';
import {
  KeyboardShortcuts,
  useKeyboardShortcuts,
} from '../useKeyboardShortcuts';

describe('Keyboard shortcuts for components', () => {
  describe('useKeyboardShortcuts', () => {
    it('should fire a function when keydown is detected', () => {
      const shortcut = {
        KeyK: jest.fn(),
      };

      renderHook(() => useKeyboardShortcuts(shortcut, document));
      fireEvent.keyDown(document, { code: 'KeyK' });

      expect(shortcut.KeyK).toHaveBeenCalledTimes(1);
    });

    it('should fire a function when chained keydown is detected', () => {
      const shortcut = {
        'KeyA~KeyB': jest.fn(),
      };

      renderHook(() => useKeyboardShortcuts(shortcut, document));
      fireEvent.keyDown(document, { code: 'KeyA' });
      fireEvent.keyDown(document, { code: 'KeyB' });

      expect(shortcut['KeyA~KeyB']).toHaveBeenCalledTimes(1);
    });

    it('should not fire a function when chained keydown is missed, timeout should only be 0ms', async () => {
      const shortcut = {
        'KeyA~KeyB': jest.fn(),
      };

      const timeout = 0;

      renderHook(() => useKeyboardShortcuts(shortcut, document, { timeout }));
      fireEvent.keyDown(document, { code: 'KeyA' });

      await new Promise((resolve) =>
        setTimeout(() => {
          fireEvent.keyDown(document, { code: 'KeyB' });
          resolve();
        }, 25),
      );

      expect(shortcut['KeyA~KeyB']).not.toHaveBeenCalled();
    });

    it('should not add event listener if shortcut object is empty', () => {
      HTMLDocument.prototype.addEventListener = jest.fn();

      renderHook(() => useKeyboardShortcuts({}, document));

      expect(HTMLDocument.prototype.addEventListener).not.toHaveBeenCalled();
    });

    it('should add event listener to window', () => {
      HTMLDocument.prototype.addEventListener = jest.fn();

      const shortcut = {
        KeyK: null,
      };

      renderHook(() => useKeyboardShortcuts(shortcut, document));

      expect(HTMLDocument.prototype.addEventListener).toHaveBeenCalledTimes(1);
    });

    it('should not fire a function when keydown is detected in element', () => {
      const shortcut = {
        KeyK: jest.fn(),
      };
      const eventTarget = document.createElement('textarea'); // eventTarget set since the default is window

      renderHook(() => useKeyboardShortcuts(shortcut, document), eventTarget);
      fireEvent.keyDown(eventTarget, { code: 'KeyK' });

      expect(shortcut.KeyK).not.toHaveBeenCalled();
    });

    it('should remove event listener when the hook is unmounted', () => {
      HTMLDocument.prototype.addEventListener = jest.fn();
      HTMLDocument.prototype.removeEventListener = jest.fn();

      const shortcut = {
        KeyK: null,
      };

      const { unmount } = renderHook(() =>
        useKeyboardShortcuts(shortcut, document),
      );

      unmount();

      expect(HTMLDocument.prototype.addEventListener).toHaveBeenCalledTimes(1);
      expect(HTMLDocument.prototype.removeEventListener).toHaveBeenCalledTimes(
        1,
      );
    });
  });

  describe('<KeyboardShortcuts />', () => {
    it('should not add event listener if shortcut object is empty', async () => {
      HTMLDocument.prototype.addEventListener = jest.fn();

      render(<KeyboardShortcuts eventTarget={document} />);

      expect(HTMLDocument.prototype.addEventListener).not.toHaveBeenCalled();
    });

    it('should add event listener to window', async () => {
      HTMLDocument.prototype.addEventListener = jest.fn();

      render(
        <KeyboardShortcuts eventTarget={document} shortcuts={{ KeyK: null }} />,
      );

      expect(HTMLDocument.prototype.addEventListener).toHaveBeenCalledTimes(1);
    });

    it('should remove event listener when the hook is unmounted', async () => {
      HTMLDocument.prototype.addEventListener = jest.fn();
      HTMLDocument.prototype.removeEventListener = jest.fn();

      const { unmount } = render(
        <KeyboardShortcuts eventTarget={document} shortcuts={{ KeyK: null }} />,
      );

      unmount();
      expect(HTMLDocument.prototype.addEventListener).toHaveBeenCalledTimes(1);
      expect(HTMLDocument.prototype.removeEventListener).toHaveBeenCalledTimes(
        1,
      );
    });
  });
});
