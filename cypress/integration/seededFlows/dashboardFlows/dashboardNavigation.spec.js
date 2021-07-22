describe.skip('Dashboard navigation', () => {
  beforeEach(() => {
    cy.testSetup();
    cy.fixture('users/articleEditorV1User.json').as('user');

    cy.intercept('/api/followers/**', []);
    cy.intercept('/followings/**', []);

    cy.get('@user').then((user) => {
      cy.loginAndVisit(user, '/dashboard');
    });
  });

  it('Shows the Posts dashboard', () => {
    cy.findByRole('heading', { name: 'Posts' });
    cy.findByRole('navigation').within(() => {
      cy.findByRole('link', { name: /Posts/ }).should(
        'have.attr',
        'aria-current',
        'page',
      );

      const otherLinks = [
        /Series/,
        /Followers/,
        /Following tags/,
        /Following users/,
        /Following organizations/,
        /Following podcasts/,
      ];
      otherLinks.forEach((name) => {
        cy.findByRole('link', { name }).should('not.have.attr', 'aria-current');
      });
    });
  });

  it('Shows the Series dashboard', () => {
    cy.findByRole('link', { name: /Series/ }).click();

    // The Series dashboard does not show the sidebar like the others
    cy.findByRole('heading', { name: "Article Editor v1 User's Series" });
  });

  it('Shows the Followers dashboard', () => {
    cy.findByRole('link', { name: /Followers/ }).click();
    cy.findByRole('heading', { name: 'Dashboard » Followers' });

    cy.findByRole('navigation', { name: 'Dashboards' }).within(() => {
      cy.findByRole('link', { name: /Followers/ }).should(
        'have.attr',
        'aria-current',
        'page',
      );
      const otherLinks = [
        /Posts/,
        /Series/,
        /Following tags/,
        /Following users/,
        /Following organizations/,
        /Following podcasts/,
      ];
      otherLinks.forEach((name) => {
        cy.findByRole('link', { name }).should('not.have.attr', 'aria-current');
      });
    });
  });

  it('Shows the Following tags dashboard', () => {
    cy.findByRole('link', { name: /Following tags/ }).click();
    cy.findByRole('heading', { name: 'Dashboard » Following tags' });
    const otherLinks = [
      /Posts/,
      /Series/,
      /Followers/,
      /Following users/,
      /Following organizations/,
      /Following podcasts/,
    ];
    otherLinks.forEach((name) => {
      cy.findByRole('link', { name }).should('not.have.attr', 'aria-current');
    });
  });

  it('Shows the Following users dashboard', () => {
    cy.findByRole('link', { name: /Following users/ }).click();
    cy.findByRole('heading', { name: 'Dashboard » Following users' });

    const otherLinks = [
      /Posts/,
      /Series/,
      /Followers/,
      /Following tags/,
      /Following organizations/,
      /Following podcasts/,
    ];
    otherLinks.forEach((name) => {
      cy.findByRole('link', { name }).should('not.have.attr', 'aria-current');
    });
  });

  it('Shows the Following organizations dashboard', () => {
    cy.findByRole('link', { name: /Following organizations/ }).click();
    cy.findByRole('heading', { name: 'Dashboard » Following organizations' });

    const otherLinks = [
      /Posts/,
      /Series/,
      /Followers/,
      /Following tags/,
      /Following users/,
      /Following podcasts/,
    ];
    otherLinks.forEach((name) => {
      cy.findByRole('link', { name }).should('not.have.attr', 'aria-current');
    });
  });

  it('Shows the Following podcasts dashboard', () => {
    cy.findByRole('link', { name: /Following podcasts/ }).click();
    cy.findByRole('heading', { name: 'Dashboard » Following podcasts' });

    const otherLinks = [
      /Posts/,
      /Series/,
      /Followers/,
      /Following tags/,
      /Following users/,
      /Following organizations/,
    ];
    otherLinks.forEach((name) => {
      cy.findByRole('link', { name }).should('not.have.attr', 'aria-current');
    });
  });
});
