describe('Home Feed Navigation', () => {
  beforeEach(() => {
    cy.testSetup();
    cy.fixture('users/articleEditorV1User.json').as('user');

    cy.get('@user').then((user) => {
      cy.loginUser(user).then(() => {
        cy.visit('/');
      });
    });
  });

  it('should show Feed by default', () => {
    cy.findByRole('navigation', { name: 'View posts by' }).within(() => {
      cy.findByRole('link', { name: 'Feed' }).as('feed');
      cy.findByRole('link', { name: 'Week' }).as('week');
      cy.findByRole('link', { name: 'Month' }).as('month');
      cy.findByRole('link', { name: 'Year' }).as('year');
      cy.findByRole('link', { name: 'Infinity' }).as('infinity');

      cy.findByRole('link', { name: 'Feed' }).should(
        'have.attr',
        'aria-current',
        'page',
      );

      cy.get('@week').should('have.attr', 'aria-current', '');
      cy.get('@month').should('have.attr', 'aria-current', '');
      cy.get('@year').should('have.attr', 'aria-current', '');
      cy.get('@infinity').should('have.attr', 'aria-current', '');
    });
  });

  it('should navigate to Week view', () => {
    cy.findByRole('navigation', { name: 'View posts by' }).within(() => {
      cy.findByRole('link', { name: 'Week' }).as('week');
      cy.get('@week').should('have.attr', 'aria-current', '');
      cy.get('@week').click();
    });

    cy.url().should('contain', '/top/week');
    // Get a fresh handle to elements, as we've navigated to a new page
    cy.findByRole('navigation', { name: 'View posts by' }).within(() => {
      cy.findByRole('link', { name: 'Week' }).should(
        'have.attr',
        'aria-current',
        'page',
      );
    });
  });

  it('should navigate to Month view', () => {
    cy.findByRole('navigation', { name: 'View posts by' }).within(() => {
      cy.findByRole('link', { name: 'Month' }).as('month');
      cy.get('@month').should('have.attr', 'aria-current', '');
      cy.get('@month').click();
    });

    cy.url().should('contain', '/top/month');
    // Get a fresh handle to elements, as we've navigated to a new page
    cy.findByRole('navigation', { name: 'View posts by' }).within(() => {
      cy.findByRole('link', { name: 'Month' }).should(
        'have.attr',
        'aria-current',
        'page',
      );
    });
  });

  it('should navigate to Year view', () => {
    cy.findByRole('navigation', { name: 'View posts by' }).within(() => {
      cy.findByRole('link', { name: 'Year' }).as('year');
      cy.get('@year').should('have.attr', 'aria-current', '');
      cy.get('@year').click();
    });

    cy.url().should('contain', '/top/year');
    // Get a fresh handle to elements, as we've navigated to a new page
    cy.findByRole('navigation', { name: 'View posts by' }).within(() => {
      cy.findByRole('link', { name: 'Year' }).should(
        'have.attr',
        'aria-current',
        'page',
      );
    });
  });

  it('should navigate to Infinity view', () => {
    cy.findByRole('navigation', { name: 'View posts by' }).within(() => {
      cy.findByRole('link', { name: 'Infinity' }).as('infinity');
      cy.get('@infinity').should('have.attr', 'aria-current', '');
      cy.get('@infinity').click();
    });

    cy.url().should('contain', '/top/infinity');
    // Get a fresh handle to elements, as we've navigated to a new page
    cy.findByRole('navigation', { name: 'View posts by' }).within(() => {
      cy.findByRole('link', { name: 'Infinity' }).should(
        'have.attr',
        'aria-current',
        'page',
      );
    });
  });
});
