describe('Subscribe to article comments', () => {
  beforeEach(() => {
    cy.testSetup();
    cy.fixture('users/articleEditorV1User.json').as('user');

    cy.get('@user').then((user) => {
      cy.loginUser(user).then(() => {
        cy.createArticle({
          title: 'My article',
          tags: ['beginner', 'ruby', 'go'],
          content: `This is a test article's contents.`,
          published: true,
        }).then((response) => {
          cy.visit(response.body.current_state_path);
        });
      });
    });
  });

  it('should show a dropdown of subscription preferences', () => {
    cy.findByRole('main').within(() => {
      cy.findByRole('button', { name: 'Unsubscribe' });
      cy.findByRole('button', { name: 'Preferences' }).as('preferencesButton');
      cy.get('@preferencesButton').click();

      // Verify the expected options appear
      cy.findByRole('radio', {
        name: 'All comments You’ll receive notifications for all new comments.',
      })
        .should('have.focus')
        .should('be.checked');
      cy.findByRole('radio', {
        name: 'Top-level comments You’ll receive notifications only for all new top-level comments.',
      });
      cy.findByRole('radio', {
        name: 'Post author comments You’ll receive notifications only if post author sends a new comment.',
      });

      // Verify that the Done button closes the dropdown
      cy.findByRole('button', { name: 'Done' }).click();
      cy.get('@preferencesButton').should('have.focus');

      //   Verify that clicking the Preferences button twice also closes the dropdown
      cy.get('@preferencesButton').click();
      cy.findByRole('button', { name: 'Done' });
      cy.get('@preferencesButton').click();
      cy.findByRole('button', { name: 'Done' }).should('not.exist');
    });

    // Verify that the Escape key also closes the dropdown
    cy.get('@preferencesButton').click();
    cy.findByRole('button', { name: 'Done' });
    cy.get('body').type('{esc}');
    cy.findByRole('button', { name: 'Done' }).should('not.exist');
  });

  it('should update subscription preferences', () => {
    cy.findByRole('main').within(() => {
      cy.findByRole('button', { name: 'Preferences' }).click();
      cy.findByRole('radio', {
        name: 'Top-level comments You’ll receive notifications only for all new top-level comments.',
      }).check();
      cy.findByRole('button', { name: 'Done' }).click();
    });
    cy.findByText('You have been subscribed to top level comments').should(
      'exist',
    );
  });

  it('should unsubscribe from comments', () => {
    cy.findByRole('main').within(() => {
      cy.findByRole('button', { name: 'Unsubscribe' }).click();

      cy.findByRole('button', { name: 'Unsubscribe' }).should('not.exist');
      cy.findByRole('button', { name: 'Preferences' }).should('not.exist');
      cy.findByRole('button', { name: 'Subscribe' });
    });
  });
});
