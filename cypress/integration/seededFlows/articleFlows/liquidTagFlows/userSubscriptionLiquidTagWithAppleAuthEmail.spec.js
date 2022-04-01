describe('User subscription liquid tag - apple auth email', () => {
  beforeEach(() => {
    cy.testSetup();

    cy.fixture('users/appleAuthAdminUser.json').as('user');

    cy.get('@user').then((user) => {
      cy.loginUser(user).then(() => {
        cy.createArticle({
          title: 'User subscription liquid tag article',
          tags: ['beginner', 'ruby', 'go'],
          content: `{% user_subscription CTA text for first tag %}\nSome text\n{% user_subscription CTA text for second tag %}`,
          published: true,
        }).then((response) => {
          cy.visitAndWaitForUserSideEffects(response.body.current_state_path);
          // Wait for page to load
          cy.findByRole('heading', {
            name: 'User subscription liquid tag article',
          });
        });
      });
    });
  });

  it('informs user they must change email address to subscribe', () => {
    // Check both liquid tags are shown
    cy.findByRole('heading', { name: 'CTA text for first tag' });
    cy.findByRole('heading', { name: 'CTA text for second tag' });

    // User should not be able to subscribe
    cy.findAllByRole('button', { name: 'Subscribe' })
      .last()
      .should('have.attr', 'disabled');

    cy.findAllByRole('link', {
      name: 'update your email address in Settings',
    }).should('have.length', 2);

    cy.findAllByText(
      /you signed up with Apple using a private relay email/,
    ).should('have.length', 2);
  });
});
