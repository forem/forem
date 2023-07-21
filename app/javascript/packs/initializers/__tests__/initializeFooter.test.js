import { toggleFooterVisibility } from '../initializeFooter';

describe('initializeFooter', () => {
  beforeEach(() => {
    document.body.innerHTML = `
      <div id="footer"></div>
    `;
  });

  it('should hide the footer when on the home page ("/")', () => {
    window.history.pushState({}, 'Home', '/');

    toggleFooterVisibility();

    const footer = document.querySelector('#footer');
    expect(footer.style.display).toBe('none');
  });

  it('should show the footer when not on the home page', () => {
    window.history.pushState({}, 'Other Page', '/about');

    toggleFooterVisibility();

    const footer = document.querySelector('#footer');
    expect(footer.style.display).toBe('block');
  });
});
