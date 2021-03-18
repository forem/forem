describe('Runtime Context', () => {
  beforeEach(() => {
    cy.testSetup();
  });

  it('should detect Linux browser context', () => {
    const linuxUserAgent = {
      'user-agent':
        'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/77.0.3865.120 Safari/537.36',
    };

    // Go to home page
    cy.visit('/', { headers: linuxUserAgent });

    const fn = () => {
      delete navigator.platform;
      Object.defineProperty(navigator, 'platform', {
        get: function () {
          return 'Linux';
        }, // Or just get: () => 'bar',
        configurable: true,
      });
    };

    cy.wrap({ foo: fn }).invoke('foo');

    // Check the body's data-runtime attribute
    cy.get('body').should('have.attr', 'data-runtime', 'Browser-Linux');
  });
});
