/**
 * Check color contrast according to WCAG 2.0 spec
 * @see http://www.w3.org/TR/WCAG20-TECHS/G17.html
 * Based on original implementation
 * https://github.com/doochik/wcag-color-contrast
 */
export const WCAGColorContrast = {
  /**
   * Calculate contrast ratio between rgb1 and rgb2
   * @param {String} rgb1 6-letter RGB color.
   * @param {String} rgb2 6-letter RGB color.
   * @return {Number}
   */
  ratio(rgb1, rgb2) {
    let sRGB1;
    let sRGB2;

    if (this.validRGB(rgb1)) {
      sRGB1 = this.RGBtosRGB(rgb1);
    } else {
      throw `Invalid color ${rgb1}`;
    }
    if (this.validRGB(rgb2)) {
      sRGB2 = this.RGBtosRGB(rgb2);
    } else {
      throw `Invalid color ${rgb2}`;
    }

    const L1 = this.sRGBLightness(sRGB1);
    const L2 = this.sRGBLightness(sRGB2);

    /*
    Calculate the contrast ratio using the following formula.
    (L1 + 0.05) / (L2 + 0.05), where
        L1 is the relative luminance of the lighter of the foreground or background colors, and
        L2 is the relative luminance of the darker of the foreground or background colors.
     */
    return L1 > L2 ? (L1 + 0.05) / (L2 + 0.05) : (L2 + 0.05) / (L1 + 0.05);
  },

  /**
   * Convert RGB color to sRGB
   * @param {String} rgb 6-letter RGB color.
   * @return {Number[]} [R, G, B]
   */
  RGBtosRGB(rgb) {
    if (rgb.length === 3) {
      rgb = rgb[0] + rgb[0] + rgb[1] + rgb[1] + rgb[2] + rgb[2];
    }
    return [
      parseInt(rgb.slice(0, 2), 16) / 255,
      parseInt(rgb.slice(2, 4), 16) / 255,
      parseInt(rgb.slice(4, 6), 16) / 255,
    ];
  },

  /**
   * Calculate lightness for sRGB color.
   * @param {Number[]} sRGB sRGB color [R, G, B]
   * @return {Number}
   */
  sRGBLightness(sRGB) {
    // L = 0.2126 * R + 0.7152 * G + 0.0722 * B where R, G and B are defined as
    // if R <= 0.03928 then R = R sRGB /12.92 else R = ((R sRGB +0.055)/1.055) ^ 2.4
    // if G <= 0.03928 then G = G sRGB /12.92 else G = ((G sRGB +0.055)/1.055) ^ 2.4
    // if B <= 0.03928 then B = B sRGB /12.92 else B = ((B sRGB +0.055)/1.055) ^ 2.4
    const RsRGB = sRGB[0];
    const GsRGB = sRGB[1];
    const BsRGB = sRGB[2];

    return (
      0.2126 *
        (RsRGB <= 0.03928
          ? RsRGB / 12.92
          : Math.pow((RsRGB + 0.055) / 1.055, 2.4)) +
      0.7152 *
        (GsRGB <= 0.03928
          ? GsRGB / 12.92
          : Math.pow((GsRGB + 0.055) / 1.055, 2.4)) +
      0.0722 *
        (BsRGB <= 0.03928
          ? BsRGB / 12.92
          : Math.pow((BsRGB + 0.055) / 1.055, 2.4))
    );
  },

  /**
   * Validate RGB string.
   * @param {String} rgb Color.
   * @return {Boolean}
   */
  validRGB(rgb) {
    return rgb && (/^[a-f0-9]{3}$/i.test(rgb) || /^[a-f0-9]{6}$/i.test(rgb));
  },
};
