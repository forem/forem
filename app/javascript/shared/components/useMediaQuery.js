import { useState, useEffect } from 'preact/hooks';

/**
 * Pre-defined breakpoints for width.
 *
 * Note: These were copied from _import.scss.
 */
export const BREAKPOINTS = Object.freeze({
  Small: '640',
  Medium: '768',
  Large: '1024',
});

/**
 * A custom Preact hook for evaluating whether or not a CSS media query is matched or not.
 *
 * @param {string} query The media query to evaluate.
 *
 * @returns {boolean} True if the media query is matched, false otherwise.
 *
 * @example
 * import { useMediaQuery } from '@components/useMediaQuery';
 *
 * function SomeComponent({ query }) {
 *    const matchesBreakpoint = useMediaQuery(query);
 *
 *    if (!matchesBreakpoint) {
 *      return null;
 *    }
 *
 *    return <SomeComponentThatMatchesMediaQuery />
 * }
 */
export const useMediaQuery = (query) => {
  const mediaQuery = window.matchMedia(query);

  const [match, setMatch] = useState(!!mediaQuery.matches);

  useEffect(() => {
    const handler = () => {
      setMatch(!!mediaQuery.matches);
    };
    mediaQuery.addListener(handler);

    return () => mediaQuery.removeListener(handler);
  });

  return match;
};
