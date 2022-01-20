describe('Tag index page navigation', () => {
  beforeEach(() => {
    cy.testSetup();
    cy.fixture('users/articleEditorV1User.json').as('user');

    cy.get('@user').then((user) => {
      cy.loginAndVisit(user, '/t/tag1');
    });
  });

  it('shows Relevant by default', () => {
    cy.findByRole('navigation', { name: 'View tagged posts by' }).within(() => {
      cy.findByRole('link', { name: 'Relevant' }).as('relevant');
      cy.findByRole('link', { name: 'Top' }).as('top');
      cy.findByRole('link', { name: 'Latest' }).as('latest');

      cy.get('@relevant').should('have.attr', 'aria-current', 'page');

      cy.get('@top').should('not.have.attr', 'aria-current');
      cy.get('@latest').should('not.have.attr', 'aria-current');
    });
  });

  it('should navigate to Week view by default for Top', () => {
    cy.findByRole('navigation', { name: 'View tagged posts by' }).within(() => {
      cy.findByRole('link', { name: 'Top' }).as('top');
      cy.get('@top').click();
    });

    cy.url().should('contain', '/top/week');
    // Get a fresh handle to elements, as we've navigated to a new page
    cy.findByRole('navigation', { name: 'View tagged posts by' }).within(() => {
      cy.findByRole('link', { name: 'Week' }).as('week');

      cy.get('@week').should('have.attr', 'aria-current', 'page');

      cy.get('@week').click(); // should not change the page
      cy.url().should('contain', '/top/week'); // so the url stays the same
    });
  });

  it('should navigate to Month view', () => {
    cy.findByRole('navigation', { name: 'View tagged posts by' }).within(() => {
      cy.findByRole('link', { name: 'Top' }).as('top');
      cy.get('@top').click();
    });

    // this url check serves to wait for the page transition
    cy.url().should('contain', '/top/week');

    cy.findByRole('navigation', { name: 'View tagged posts by' }).within(() => {
      cy.findByRole('link', { name: 'Month' }).as('month');
      cy.get('@month').should('not.have.attr', 'aria-current');
      cy.get('@month').click();
    });

    cy.url().should('contain', '/top/month');
    // Get a fresh handle to elements, as we've navigated to a new page
    cy.findByRole('navigation', { name: 'View tagged posts by' }).within(() => {
      cy.findByRole('link', { name: 'Month' }).should(
        'have.attr',
        'aria-current',
        'page',
      );
    });
  });

  it('should navigate to Year view', () => {
    cy.findByRole('navigation', { name: 'View tagged posts by' }).within(() => {
      cy.findByRole('link', { name: 'Top' }).as('top');
      cy.get('@top').click();
    });

    // this url check serves to wait for the page transition
    cy.url().should('contain', '/top/week');

    cy.findByRole('navigation', { name: 'View tagged posts by' }).within(() => {
      cy.findByRole('link', { name: 'Year' }).as('year');
      cy.get('@year').should('not.have.attr', 'aria-current');
      cy.get('@year').click();
    });

    cy.url().should('contain', '/top/year');
    // Get a fresh handle to elements, as we've navigated to a new page
    cy.findByRole('navigation', { name: 'View tagged posts by' }).within(() => {
      cy.findByRole('link', { name: 'Year' }).should(
        'have.attr',
        'aria-current',
        'page',
      );
    });
  });

  it('should navigate to Infinity view', () => {
    cy.findByRole('navigation', { name: 'View tagged posts by' }).within(() => {
      cy.findByRole('link', { name: 'Top' }).as('top');
      cy.get('@top').click();
    });

    // this url check serves to wait for the page transition
    cy.url().should('contain', '/top/week');

    cy.findByRole('navigation', { name: 'View tagged posts by' }).within(() => {
      cy.findByRole('link', { name: 'Infinity' }).as('infinity');
      cy.get('@infinity').should('not.have.attr', 'aria-current');
      cy.get('@infinity').click();
    });

    cy.url().should('contain', '/top/infinity');
    // Get a fresh handle to elements, as we've navigated to a new page
    cy.findByRole('navigation', { name: 'View tagged posts by' }).within(() => {
      cy.findByRole('link', { name: 'Infinity' }).should(
        'have.attr',
        'aria-current',
        'page',
      );
    });
  });
});
