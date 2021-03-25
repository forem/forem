import { renderHook } from '@testing-library/preact-hooks';
import { cleanup } from '@testing-library/preact';
import { useMediaQuery } from '@components/useMediaQuery';

describe('useMediaQuery', () => {
  it('should return false if the media query is not matched', () => {
    const addListener = jest.fn();
    const removeListener = jest.fn();

    global.window.matchMedia = jest.fn((query) => {
      return {
        matches: false,
        media: query,
        addListener,
        removeListener,
      };
    });

    const { result } = renderHook(() => useMediaQuery('some media query'));

    expect(addListener).toHaveBeenCalledTimes(1);
    expect(result.current).toEqual(false);

    cleanup();
    expect(removeListener).toHaveBeenCalledTimes(1);
  });

  it('should return true if the media query is not matched', () => {
    const addListener = jest.fn();
    const removeListener = jest.fn();

    global.window.matchMedia = jest.fn((query) => {
      return {
        matches: true,
        media: query,
        addListener,
        removeListener,
      };
    });

    const { result } = renderHook(() => useMediaQuery('some media query'));

    expect(addListener).toHaveBeenCalledTimes(1);
    expect(result.current).toEqual(true);

    cleanup();
    expect(removeListener).toHaveBeenCalledTimes(1);
  });
});
