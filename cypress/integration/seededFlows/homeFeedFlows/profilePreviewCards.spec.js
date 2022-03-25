describe('Home feed profile preview cards', () => {
  beforeEach(() => {
    cy.testSetup();
    cy.fixture('users/articleEditorV1User.json').as('user');
    cy.get('@user').then((user) => {
      cy.loginAndVisit(user, '/');
      // Wait until we're on the home feed, and it's finished loading
      cy.findByRole('heading', { name: 'Posts' });
      cy.findByTestId('feed-loading').should('not.exist');
    });
  });

  // Helper function for `pipe` command, allowing us to retry clicks in case JS handler is not yet attached
  const click = (el) => el.click();

  it("shows a profile preview card for a post's author", () => {
    cy.findAllByRole('button', { name: 'Admin McAdmin profile details' })
      .first()
      .as('previewButton');

    // We add the extra call to focus() because the Cypress click event doesn't reliably trigger the `focusin` listener we use to populate card metadata
    cy.get('@previewButton')
      .pipe(click)
      .should('have.attr', 'aria-expanded', 'true')
      .focus();

    cy.get('@previewButton')
      .closest('.profile-preview-card')
      .within(() => {
        // Check all the expected user data sections are present
        cy.findByText('Admin user summary').should('exist');
        cy.findByText('Software developer at Company');
        cy.findByText('Edinburgh');
        cy.findByText('University of Life');

        // Check the follow button works as expected
        cy.findByRole('button', { name: 'Follow user: Admin McAdmin' })
          .should('have.attr', 'aria-pressed', 'false')
          .click()
          .should('have.text', 'Following')
          .should('have.attr', 'aria-pressed', 'true');
      });
  });

  // Regression test for https://github.com/forem/forem/issues/16734
  it('handles users with punctuation in the name', () => {
    cy.findAllByRole('button', {
      name: 'User "The test breaker" A\'postrophe \\:/ profile details',
    })
      .first()
      .as('previewButton');

    cy.get('@previewButton')
      .pipe(click)
      .should('have.attr', 'aria-expanded', 'true');

    cy.findByRole('button', {
      name: 'Follow user: User "The test breaker" A\'postrophe \\:/',
    }).as('userFollowButton');
    cy.get('@userFollowButton').should('have.attr', 'aria-pressed', 'false');
    cy.get('@userFollowButton').click();

    cy.get('@userFollowButton').should('have.text', 'Following');
    cy.get('@userFollowButton').should('have.attr', 'aria-pressed', 'true');
  });
});
