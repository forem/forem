describe('Home feed profile preview cards', () => {
  beforeEach(() => {
    cy.testSetup();
    cy.fixture('users/articleEditorV1User.json').as('user');
    cy.get('@user').then((user) => {
      cy.loginAndVisit(user, '/');
    });
  });

  it("shows a profile preview card for a post's author", () => {
    cy.findAllByRole('button', { name: 'Admin McAdmin profile details' })
      .first()
      .as('previewButton');
    cy.get('@previewButton').should('have.attr', 'data-initialized');
    cy.get('@previewButton').click();

    cy.findAllByTestId('profile-preview-card')
      .first()
      .within(() => {
        cy.findByRole('link', {
          name: 'Admin McAdmin',
        }).should('have.focus');

        // Check all the expected user data sections are present
        cy.findByText('Admin user summary');
        cy.findByText('Software developer at Company');
        cy.findByText('Edinburgh');
        cy.findByText('University of Life');

        cy.findByRole('button', { name: 'Follow user: Admin McAdmin' }).as(
          'userFollowButton',
        );
        cy.get('@userFollowButton').should(
          'have.attr',
          'aria-pressed',
          'false',
        );
        cy.get('@userFollowButton').click();

        cy.get('@userFollowButton').should('have.text', 'Following');
        cy.get('@userFollowButton').should('have.attr', 'aria-pressed', 'true');
      });
  });

  // Regression test for https://github.com/forem/forem/issues/16734
  it('handles users with punctuation in the name', () => {
    cy.findAllByRole('button', {
      name: 'User "The test breaker" A\'postrophe \\:/ profile details',
    }).as('previewButton');
    cy.get('@previewButton').should('have.attr', 'data-initialized');
    cy.get('@previewButton').click();

    cy.findByRole('button', {
      name: 'Follow user: User "The test breaker" A\'postrophe \\:/',
    }).as('userFollowButton');
    cy.get('@userFollowButton').should('have.attr', 'aria-pressed', 'false');
    cy.get('@userFollowButton').click();

    cy.get('@userFollowButton').should('have.text', 'Following');
    cy.get('@userFollowButton').should('have.attr', 'aria-pressed', 'true');
  });
});
