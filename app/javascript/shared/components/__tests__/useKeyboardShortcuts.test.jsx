import { h } from 'preact';
import { renderHook } from '@testing-library/preact-hooks';
import { fireEvent } from '@testing-library/user-event';
import { KeyboardShortcuts, useKeyboardShortcuts } from '../useKeyboardShortcuts.jsx';

describe('Keyboard shortcuts for components', () => {
  describe('useKeyboardShortcuts', () => {
    it('should not add event listener if shortcut object is empty', () => {
      HTMLDocument.prototype.addEventListener = jest.fn();

      renderHook(() =>
        useKeyboardShortcuts({}, document),
      );

      expect(HTMLDocument.prototype.addEventListener).not.toHaveBeenCalled();
    });

    it('should add event listener to window', () => {
      HTMLDocument.prototype.addEventListener = jest.fn();

      renderHook(() =>
        useKeyboardShortcuts({
          KeyK: () => { }
        }, document),
      );

      expect(HTMLDocument.prototype.addEventListener).toHaveBeenCalledTimes(1);
    });

    it('should fire a function when keydown is detected', () => {
      const keyPress = jest.fn();

      renderHook(() =>
        useKeyboardShortcuts({
          KeyK: keyPress
        }, document),
      );
      fireEvent.keydown(document, { code: "KeyK" });

      expect(keyPress).toHaveBeenCalledTimes(1);
    });

    it('should not fire a function when keydown is detected in element', () => {
      const keyPress = jest.fn();
      const eventTarget = document.createElement('textarea') // eventTarget set since the default is window

      renderHook(() =>
        useKeyboardShortcuts({
          KeyK: keyPress
        }, document),
        eventTarget,
      );
      fireEvent.keyDown(eventTarget, { code: "KeyK" });

      expect(keyPress).not.toHaveBeenCalled();
    });

    it('should remove event listener when the hook is unmounted', () => {
      HTMLDocument.prototype.addEventListener = jest.fn();
      HTMLDocument.prototype.removeEventListener = jest.fn();

      const { unmount } = renderHook(() =>
        useKeyboardShortcuts({
          KeyK: () => { }
        }, document),
      );

      unmount();

      expect(HTMLDocument.prototype.addEventListener).toHaveBeenCalledTimes(1);
      expect(HTMLDocument.prototype.removeEventListener).toHaveBeenCalledTimes(1);
    });
  });

  describe('<KeyboardShortcuts />', () => {
    it('should not add event listener if shortcut object is empty', () => {
      HTMLDocument.prototype.addEventListener = jest.fn();

      renderHook(() =>
        <KeyboardShortcuts eventTarget={document} />,
      );

      expect(HTMLDocument.prototype.addEventListener).not.toHaveBeenCalled();
    });

    it('should add event listener to window', () => {
      HTMLDocument.prototype.addEventListener = jest.fn();

      renderHook(() =>
        <KeyboardShortcuts eventTarget={document} shortcuts={{
          KeyK: () => { }
        }} />,
      );

      expect(HTMLDocument.prototype.addEventListener).toHaveBeenCalledTimes(1);
    });

    it('should remove event listener when the hook is unmounted', () => {
      HTMLDocument.prototype.addEventListener = jest.fn();
      HTMLDocument.prototype.removeEventListener = jest.fn();

      const { unmount } = renderHook(() =>
        <KeyboardShortcuts eventTarget={document} shortcuts={{
          KeyK: () => { }
        }} />,
      );

      unmount();
      expect(HTMLDocument.prototype.addEventListener).toHaveBeenCalledTimes(1);
      expect(HTMLDocument.prototype.removeEventListener).toHaveBeenCalledTimes(1);
    });
  });
});
