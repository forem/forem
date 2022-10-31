describe('User subscription liquid tag - subscribable email', () => {
  beforeEach(() => {
    cy.testSetup();

    cy.fixture('users/adminUser.json').as('user');

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

  it('shows the signed in UI and subscribes', () => {
    cy.findByRole('heading', { name: 'CTA text for first tag' });
    cy.findByRole('heading', { name: 'CTA text for second tag' });
    cy.findAllByRole('button', { name: 'Subscribe' }).should('have.length', 2);
    cy.findAllByRole('link', {
      name: 'update your email address in Settings',
    }).should('have.length', 2);

    cy.findAllByRole('button', { name: 'Subscribe' }).last().click();

    cy.findByTestId('modal-container').as('modal');

    cy.get('@modal')
      .findByRole('button', { name: 'Confirm subscription' })
      .click();

    cy.findAllByText(
      'You are now subscribed and may receive emails from admin_mcadmin',
    ).should('have.length', 2);
    cy.findByRole('button', { name: 'Subscribe' }).should('not.exist');
  });

  it('cancels subscription action', () => {
    cy.findAllByRole('button', { name: 'Subscribe' }).last().click();

    cy.findByTestId('modal-container').as('modal');

    cy.get('@modal').findByRole('button', { name: /Close/ }).click();

    cy.findAllByRole('button', { name: 'Subscribe' }).should('have.length', 2);
    cy.findByText(
      'You are now subscribed and may receive emails from admin_mcadmin',
    ).should('not.exist');
  });

  it('shows any error message and allows user to retry', () => {
    cy.intercept('POST', '/user_subscriptions', {
      error: 'This is an error message',
    });

    cy.findAllByRole('button', { name: 'Subscribe' }).last().click();

    cy.findByTestId('modal-container').as('modal');

    cy.get('@modal')
      .findByRole('button', { name: 'Confirm subscription' })
      .click();

    cy.findAllByText('This is an error message').should('have.length', 2);
  });

  it('shows the signed out UI', () => {
    cy.url().then(() => {
      cy.signOutUser();
      cy.findAllByRole('link', {
        name: 'User subscription liquid tag article',
      })
        .first()
        .click({ force: true });

      cy.findAllByRole('link', { name: 'Sign In' }).should('have.length', 2);
      cy.findAllByText('You must first sign in to DEV(local).').should(
        'have.length',
        2,
      );
      cy.findByRole('button', { name: 'Subscribe' }).should('not.exist');
    });
  });
});
