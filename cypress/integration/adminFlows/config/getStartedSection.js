describe('Get Started Section', () => {
  beforeEach(() => {
    cy.testSetup();
    cy.fixture('users/adminUser.json').as('user');

    cy.get('@user').then((user) => {
      cy.loginUser(user);
    });
  });

  describe('Community name setting', () => {
    it('updates the community name', () => {
      cy.get('@user').then(({ username }) => {
        cy.visit('/admin/config');

        cy.findByTestId('getStartedSectionForm').as('getStartedSectionForm');

        cy.get('@getStartedSectionForm')
          .get('#community_name')
          .clear()
          .type('Awesome community');

        cy.get('@getStartedSectionForm')
          .findByPlaceholderText('Confirmation text')
          .type(
            `My username is @${username} and this action is 100% safe and appropriate.`,
          );

        cy.get('@getStartedSectionForm')
          .findByText('Update Site Configuration')
          .click();

        cy.url().should('contains', '/admin/config');

        cy.findByText('Site configuration was successfully updated.').should(
          'be.visible',
        );

        // Page reloaded so need to get a new reference to the form.
        cy.findByTestId('getStartedSectionForm').as('getStartedSectionForm');
        cy.get('#community_name').should('have.value', 'Awesome community');
      });
    });

    it('updates the suggested tags', () => {
      cy.get('@user').then(({ username }) => {
        cy.visit('/admin/config');

        cy.findByTestId('getStartedSectionForm').as('getStartedSectionForm');

        cy.get('@getStartedSectionForm')
          .get('#suggested_tags')
          .clear()
          .type('much tag, so wow');

        cy.get('@getStartedSectionForm')
          .findByPlaceholderText('Confirmation text')
          .type(
            `My username is @${username} and this action is 100% safe and appropriate.`,
          );

        cy.get('@getStartedSectionForm')
          .findByText('Update Site Configuration')
          .click();

        cy.url().should('contains', '/admin/config');

        cy.findByText('Site configuration was successfully updated.').should(
          'be.visible',
        );

        // Page reloaded so need to get a new reference to the form.
        cy.findByTestId('getStartedSectionForm').as('getStartedSectionForm');
        cy.get('#suggested_tags').should('have.value', 'much tag,so wow');
      });
    });
  });
});
