import { setupMobilePageSel, mobilePageSelListener } from '../mobilePageSel';

describe('MobilePageSel Tests', () => {
  beforeAll(async () => {
    document.body.innerHTML = '<select id="mobile-page-selector" />';
  });

  it('attaches onchange listener to mobile page selector', () => {
    const spySel = jest.spyOn(
      document.getElementById('mobile-page-selector'),
      'addEventListener',
    );

    setupMobilePageSel();
    expect(spySel).toHaveBeenCalledWith('change', mobilePageSelListener);
  });
});
