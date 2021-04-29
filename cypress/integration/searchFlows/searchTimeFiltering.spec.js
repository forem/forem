describe('Search time period filters', () => {
  beforeEach(() => {
    cy.testSetup();
    cy.fixture('users/articleEditorV1User.json').as('user');

    cy.get('@user').then((user) => {
      cy.loginUser(user).then(() => {
        cy.visit('/search?q=example');
      });
    });
  });

  it('Shows most relevant posts by default', () => {
    cy.findByRole('navigation', { name: 'Search result sort options' }).within(
      () => {
        cy.findByRole('link', { name: 'Most Relevant' }).as('mostRelevant');
        cy.findByRole('link', { name: 'Newest' }).as('newest');
        cy.findByRole('link', { name: 'Oldest' }).as('oldest');

        cy.get('@mostRelevant').should('have.attr', 'aria-current', 'page');
        cy.get('@newest').should('not.have.attr', 'aria-current');
        cy.get('@oldest').should('not.have.attr', 'aria-current');
      },
    );
  });

  it('should navigate to Newest', () => {
    cy.findByRole('navigation', { name: 'Search result sort options' }).within(
      () => {
        cy.findByRole('link', { name: 'Newest' }).as('newest');
        cy.get('@newest').should('not.have.attr', 'aria-current');
        cy.get('@newest').click();
      },
    );
    cy.url().should(
      'contain',
      'search?q=example&sort_by=published_at&sort_direction=desc',
    );
    // Get a fresh handle to elements, as we've navigated to a new page
    cy.findByRole('navigation', { name: 'Search result sort options' }).within(
      () => {
        cy.findByRole('link', { name: 'Newest' }).should(
          'have.attr',
          'aria-current',
          'page',
        );
      },
    );
  });

  it('should navigate to Oldest', () => {
    cy.findByRole('navigation', { name: 'Search result sort options' }).within(
      () => {
        cy.findByRole('link', { name: 'Oldest' }).as('oldest');
        cy.get('@oldest').should('not.have.attr', 'aria-current');
        cy.get('@oldest').click();
      },
    );
    cy.url().should(
      'contain',
      'search?q=example&sort_by=published_at&sort_direction=asc',
    );
    // Get a fresh handle to elements, as we've navigated to a new page
    cy.findByRole('navigation', { name: 'Search result sort options' }).within(
      () => {
        cy.findByRole('link', { name: 'Oldest' }).should(
          'have.attr',
          'aria-current',
          'page',
        );
      },
    );
  });
});
