import { WCAGColorContrast } from '@utilities/color/WCAGColorContrast';

// Tests have been extracted from the original library https://github.com/doochik/wcag-color-contrast/blob/master/index.html
describe('WCAGColorContrast.validRGB', () => {
  it('valid #FFFFFF', () => {
    expect(WCAGColorContrast.validRGB('FFFFFF')).toBeTruthy();
  });
  it('valid #FFF', () => {
    expect(WCAGColorContrast.validRGB('FFF')).toBeTruthy();
  });
  it('valid #111', () => {
    expect(WCAGColorContrast.validRGB('111')).toBeTruthy();
  });
  it('valid #f11', () => {
    expect(WCAGColorContrast.validRGB('f11')).toBeTruthy();
  });
  it('invalid #11', () => {
    expect(WCAGColorContrast.validRGB('11')).toBeFalsy();
  });
  it('invalid #11123', () => {
    expect(WCAGColorContrast.validRGB('11123')).toBeFalsy();
  });
  it('invalid #x12345', () => {
    expect(WCAGColorContrast.validRGB('x12345')).toBeFalsy();
  });
});

describe('WCAGColorContrast.ratio', () => {
  it('#FFFFFF and #000000 must be 21', () => {
    expect(WCAGColorContrast.ratio('FFFFFF', '000000')).toBe(21);
  });

  it('#000000 and #FFFFFF must be 21', () => {
    expect(WCAGColorContrast.ratio('000000', 'FFFFFF')).toBe(21);
  });

  it('#000 and #FFF must be 21', () => {
    expect(WCAGColorContrast.ratio('000', 'FFF')).toBe(21);
  });

  it('#123 and #FFF must be 16.15', () => {
    expect(WCAGColorContrast.ratio('123', 'FFF').toFixed(2)).toBe('16.15');
  });

  it('#8883C4 and #1169FF must be 1.36', () => {
    expect(WCAGColorContrast.ratio('8883C4', '1169FF').toFixed(2)).toBe('1.36');
  });

  it('#x123 and #1169FF must throw Exception', () => {
    const test = function () {
      WCAGColorContrast.ratio('x123', '1169FF');
    };
    expect(test).toThrow();
  });
});
