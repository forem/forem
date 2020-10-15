import { h } from 'preact';
import { render } from '@testing-library/preact';
import { renderHook, act } from '@testing-library/preact-hooks';
import { KeyboardShortcuts, useKeyboardShortcuts } from '../useKeyboardShortcuts.jsx';

describe('Keyboard shortcuts for components', () => {
  describe('useKeyboardShortcuts', () => {
    it('should not add event listener if shortcut object is empty', () => {
      HTMLDocument.prototype.addEventListener = jest.fn();

      const { result } = renderHook(() =>
        useKeyboardShortcuts({}, document),
      );

      expect(HTMLDocument.prototype.addEventListener).not.toHaveBeenCalled();
    });

    it('should add event listener to window', () => {
      HTMLDocument.prototype.addEventListener = jest.fn();

      const { result } = renderHook(() =>
        useKeyboardShortcuts({
          KeyK: () => { }
        }, document),
      );

      expect(HTMLDocument.prototype.addEventListener).toHaveBeenCalledTimes(1);
    });

    it('should fire a function when keydown is detected', () => {
      const keyPress = jest.fn();
      const event = new KeyboardEvent('keydown', { code: "KeyK" });

      const { result } = renderHook(() =>
        useKeyboardShortcuts({
          KeyK: keyPress
        }, document),
      );
      window.dispatchEvent(event);

      expect(keyPress).toHaveBeenCalledTime(1);
    });

    it('should not fire a function when keydown is detected in elemement', () => {
      const keyPress = jest.fn();
      const event = new KeyboardEvent('keydown', { code: "KeyK" });
      const eventTarget = document.createElement('textarea') // eventTarget set since the default is window

      const { result } = renderHook(() =>
        useKeyboardShortcuts({
          KeyK: keyPress
        }, document),
        eventTarget,
      );
      eventTarget.dispatchEvent(event);

      expect(keyPress).not.toHaveBeenCalled();
    });

    it('should remove event listener when the hook is unmounted', () => {
      HTMLDocument.prototype.addEventListener = jest.fn();
      HTMLDocument.prototype.removeEventListener = jest.fn();

      const { result } = renderHook(() =>
        useKeyboardShortcuts({
          KeyK: () => { }
        }, document),
      );

      expect(HTMLDocument.prototype.addEventListener).toHaveBeenCalledTimes(1);
      expect(HTMLDocument.prototype.removeEventListener).toHaveBeenCalledTimes(1);
    });
  });

  describe('<KeyboardShortcuts />', () => {
    it('should not add event listener if shortcut object is empty', () => {
      HTMLDocument.prototype.addEventListener = jest.fn();

      const { result } = renderHook(() =>
        <KeyboardShortcuts eventTarget={document} />,
      );

      expect(HTMLDocument.prototype.addEventListener).not.toHaveBeenCalled();
    });

    it('should add event listener to window', () => {
      const event = new KeyboardEvent('keydown', { code: "KeyK" });

      HTMLDocument.prototype.addEventListener = jest.fn();

      const { result } = renderHook(() =>
        <KeyboardShortcuts eventTarget={document} shortcuts={{
          KeyK: () => { }
        }} />,
      );
      window.dispatchEvent(event);

      expect(HTMLDocument.prototype.addEventListener).toHaveBeenCalledTimes(1);
    });

    it('should remove event listener when the hook is unmounted', () => {
      HTMLDocument.prototype.addEventListener = jest.fn();
      HTMLDocument.prototype.removeEventListener = jest.fn();

      const { unmount, result } = renderHook(() =>
        <KeyboardShortcuts shortcuts={{
          KeyK: () => { }
        }} />,
      );

      unmount();
      expect(HTMLDocument.prototype.addEventListener).toHaveBeenCalledTimes(1);
      expect(HTMLDocument.prototype.removeEventListener).toHaveBeenCalledTimes(1);
    });
  });
});
