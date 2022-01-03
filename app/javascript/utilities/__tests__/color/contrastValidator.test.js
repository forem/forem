import { isLowContrast } from '@utilities/color/contrastValidator';

describe('Color: Contrast Validator Utilities', () => {
  it('should return a boolean indicating whether the contrast is low or not', () => {
    expect(isLowContrast('#41c3ab')).toBe(true);
    expect(isLowContrast('#4341c3')).toBe(false);
    expect(isLowContrast('#c9c5c5', '000000')).toBe(false);
    expect(isLowContrast('#544f4f', '000000')).toBe(true);
    expect(isLowContrast('#ffffff', '000000', 2)).toBe(false);
  });
});
