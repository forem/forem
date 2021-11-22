/**
 * Updates the brightness of the color
 * @param {String} color
 * @param {Integer} amount
 * Based on the ruby implementation
 * https://github.com/forem/forem/blob/main/app/services/color/compare_hex.rb
 */
export function brightness(color, amount = 1) {
  const rgbObj = hexToRgb(color);
  Object.keys(rgbObj).forEach((key) => {
    rgbObj[key] = Math.round(rgbObj[key] * amount);
  });

  return rgbToHex(rgbObj['r'], rgbObj['g'], rgbObj['b']);
}

/**
 * Converts the HEX color to an RGB color
 * @param {String} Hex color
 * @returns {Object} An object with keys for R,G,B based on the HEX color
 * @returns {null} If we cannot determine a hex pattern from the string
 */
function hexToRgb(hex) {
  const result = /^#?([a-f\d]{2})([a-f\d]{2})([a-f\d]{2})$/i.exec(hex);
  return result
    ? {
        r: parseInt(result[1], 16),
        g: parseInt(result[2], 16),
        b: parseInt(result[3], 16),
      }
    : null;
}

/**
 * Converts the RGB parameters to a HEX String
 * @param {String} Red value from RGB
 * @param {String} Green value from RGB
 * @param {String} Blue value from RGB

 * @returns {String} The converted HEX String.
 */
function rgbToHex(r, g, b) {
  return `#${rgbParameterToHex(r)}${rgbParameterToHex(g)}${rgbParameterToHex(
    b,
  )}`;
}

/**
 * Converts each RGB parameter to its corresponding HEX value
 * @param {param} This will be either red, green or blue from RGB.
 * @returns {String} The converted number to its two digit HEX String.
 */
function rgbParameterToHex(param) {
  const hex = param.toString(16);
  return hex.length == 1 ? `0${hex}` : hex;
}
