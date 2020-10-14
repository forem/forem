import { h } from 'preact';
import { render } from '@testing-library/preact';
import { renderHook, act } from '@testing-library/preact-hooks';
import { KeyboardShortcuts, useKeyboardShortcuts } from '../useKeyboardShortcuts.jsx';

describe('Keyboard shortcuts for components', () => {
  describe('useKeyboardShortcuts', () => {
    it('should not add event listener if shortcut object is empty', () => {     
      Window.prototype.addEventListener = jest.fn();
      
      const { result } = renderHook(() =>
        useKeyboardShortcuts(),
      );
      
      expect(Window.prototype.addEventListener).not.toHaveBeenCalled();
    });
    
    it('should add event listener to window', () => {
      const event = new KeyboardEvent('keydown', { code: "KeyK" });
      
      Window.prototype.addEventListener = jest.fn();
      
      const { result } = renderHook(() =>
        useKeyboardShortcuts({
          KeyK: () => { }
        }),
      );
      window.dispatchEvent(event);
      
      expect(Window.prototype.addEventListener).toHaveBeenCalledTimes(1);
    });
    
    it('should fire a function when keydown is detected', () => {
      const keyPress = jest.fn();
      const event = new KeyboardEvent('keydown', { code: "KeyK" });

      const { result } = renderHook(() =>
        useKeyboardShortcuts({
          KeyK: keyPress
        },
      );
      window.dispatchEvent(event);

      exprect(keyPress).not.toHaveBeenCalledTime(1);
    });
    
    it('should not fire a function when keydown is detected', () => {
      const keyPress = jest.fn();
      const event = new KeyboardEvent('keydown', { code: "KeyK" });
      const eventTarget = document.createElement('textarea') // eventTarget set since the default is window

      const { result } = renderHook(() =>
        useKeyboardShortcuts({
          KeyK: keyPress
        },
        eventTarget,
      );
      eventTarget.dispatchEvent(event);

      exprect(keyPress).not.toHaveBeenCalled();
    });
    
    it('should remove event listener when the hook is unmounted', () => {     
      Window.prototype.addEventListener = jest.fn();
      Window.prototype.removeEventListener = jest.fn();
      
      const { result } = renderHook(() =>
        useKeyboardShortcuts({
          KeyK: () => { }
        }),
      );
      
      expect(Window.prototype.addEventListener).toHaveBeenCalledTimes(1);
      expect(Window.prototype.removeEventListener).toHaveBeenCalledTimes(1);
    });
  });
  
  describe('<KeyboardShortcuts />', () => {
    it('should not add event listener if shortcut object is empty', () => {     
      Window.prototype.addEventListener = jest.fn();
      
      const { result } = renderHook(() =>
        <KeyboardShortcuts />,
      );
      
      expect(Window.prototype.addEventListener).not.toHaveBeenCalled();
    });
    
    it('should add event listener to window', () => {
      const event = new KeyboardEvent('keydown', { code: "KeyK" });
      
      Window.prototype.addEventListener = jest.fn();
      
      const { result } = renderHook(() =>
        <KeyboardShortcuts shortcuts={{
          KeyK: () => { }
        }} />,
      );
      window.dispatchEvent(event);
      
      expect(Window.prototype.addEventListener).toHaveBeenCalledTimes(1);
    });
    
    it('should remove event listener when the hook is unmounted', () => {     
      Window.prototype.addEventListener = jest.fn();
      Window.prototype.removeEventListener = jest.fn();
      
      const { unmount, result } = renderHook(() =>
        <KeyboardShortcuts shortcuts={{
          KeyK: () => { }
        }} />,
      );
                                               
      unmount();
      expect(Window.prototype.addEventListener).toHaveBeenCalledTimes(1);
      expect(Window.prototype.removeEventListener).toHaveBeenCalledTimes(1);
    });
  });
});
