import { initializeBillboardVisibility } from '../billboardAfterRenderActions';

describe('initializeBillboardVisibility', () => {
  const setUser = (user) => {
    global.userData = jest.fn(() => user);
  };

  const render = () => {
    document.body.innerHTML = `
      <div id="feed">
        <div id="partner" data-display-unit data-type-of="partner"></div>
        <div id="external" data-display-unit data-type-of="external"></div>
        <div id="community" data-display-unit data-type-of="community"></div>
        <div id="in-house" data-display-unit data-type-of="in_house"></div>
      </div>
      <div id="sidebar">
        <div id="sidebar-partner" data-display-unit data-type-of="partner"></div>
      </div>
    `;
  };

  const isHidden = (id) =>
    document.getElementById(id).classList.contains('hidden');

  afterEach(() => {
    delete global.userData;
  });

  it('hides partner and external billboards when the member turned sponsors off', () => {
    setUser({ display_sponsors: false });
    render();

    initializeBillboardVisibility();

    expect(isHidden('partner')).toBe(true);
    expect(isHidden('external')).toBe(true);
    expect(isHidden('community')).toBe(false);
    expect(isHidden('in-house')).toBe(false);
  });

  it('leaves every billboard visible when sponsors are on', () => {
    setUser({ display_sponsors: true });
    render();

    initializeBillboardVisibility();

    expect(isHidden('partner')).toBe(false);
    expect(isHidden('external')).toBe(false);
  });

  it('leaves every billboard visible for signed out visitors', () => {
    setUser(null);
    render();

    initializeBillboardVisibility();

    expect(isHidden('partner')).toBe(false);
  });

  it('only touches billboards inside the given root', () => {
    setUser({ display_sponsors: false });
    render();

    initializeBillboardVisibility(document.getElementById('sidebar'));

    expect(isHidden('sidebar-partner')).toBe(true);
    expect(isHidden('partner')).toBe(false);
  });

  it('shows a billboard again when sponsors are switched back on', () => {
    setUser({ display_sponsors: false });
    render();
    initializeBillboardVisibility();

    setUser({ display_sponsors: true });
    initializeBillboardVisibility();

    expect(isHidden('partner')).toBe(false);
  });
});
