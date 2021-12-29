import { WCAGColorContrast } from './WCAGColorContrast';

/**
 * Determine if the contrast ratio is low.
 * Uses the WCAGColorContrast utility library.
 *
 * @param {String} rgb1 6-letter RGB color.
 * @param {String} rgb2 6-letter RGB color.
 *
 * @return {Boolean}
 */
export function isLowContrast(
  color,
  comparedColor = 'ffffff',
  minContrast = 4.5,
) {
  return (
    WCAGColorContrast.ratio(strippedHex(color), strippedHex(comparedColor)) <
    minContrast
  );
}

/**
 * Removes the # in a string.
 *
 * @param {String} a hex color in this case.
 *
 * @return {String} without the #
 */
function strippedHex(hex) {
  return hex.replace('#', '');
}
