import { Controller } from '@hotwired/stimulus';

export class CreatorSettingsController extends Controller {
  updateBranding(event) {
    const color = event.target.value;

    document.documentElement.style.setProperty('--accent-brand', color);

    // responsible for the hover effect over the button.
    // We need to recalculate this in javascript as it's currently being calculated in ruby
    document.documentElement.style.setProperty(
      '--accent-brand-darker',
      this.updatedBrightness(color, 0.85),
    );
  }

  updatedBrightness(color, amount = 1) {
    const rgbObj = this.hexToRgb(color);
    Object.keys(rgbObj).forEach((key) => {
      rgbObj[key] = Math.round(rgbObj[key] * amount);
    });

    return this.rgbToHex(rgbObj['r'], rgbObj['g'], rgbObj['b']);
  }

  hexToRgb(hex) {
    const result = /^#?([a-f\d]{2})([a-f\d]{2})([a-f\d]{2})$/i.exec(hex);
    return result
      ? {
          r: parseInt(result[1], 16),
          g: parseInt(result[2], 16),
          b: parseInt(result[3], 16),
        }
      : null;
  }

  rgbToHex(r, g, b) {
    return `#${this.rgbParameterToHex(r)}${this.rgbParameterToHex(
      g,
    )}${this.rgbParameterToHex(b)}`;
  }

  rgbParameterToHex(param) {
    const hex = param.toString(16);
    return hex.length == 1 ? `0${hex}` : hex;
  }
}
