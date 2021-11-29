import { brightness } from '@utilities/color/accentCalculator';

describe('Color: Accent Calculator Utilities', () => {
  it('should return a hex with the adjusted brightness', () => {
    expect(brightness('#ccddee', 0.5)).toBe('#666f77');
    expect(brightness('#ccddee')).toBe('#ccddee');
    expect(brightness('#41625c', 0.85)).toBe('#37534e');
  });
});
