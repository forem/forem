describe('Follow from article liquid tag', () => {
  beforeEach(() => {
    cy.testSetup();
    cy.fixture('users/articleEditorV2User.json').as('user');

    cy.get('@user').then((user) => {
      cy.loginUser(user).then(() => {
        cy.createArticle({
          title: 'Follow from liquid tag Article',
          tags: ['beginner', 'ruby', 'go'],
          content: `{% user admin_mcadmin %}\n {% tag tag1 %}`,
          published: true,
        }).then((response) => {
          cy.visitAndWaitForUserSideEffects(response.body.current_state_path);
          // Wait for page to load
          cy.findByRole('heading', { name: 'Follow from liquid tag Article' });
        });
      });
    });
  });

  it('Follows a user from an article liquid tag', () => {
    cy.findByRole('main').within(() => {
      cy.findAllByRole('button', { name: 'Follow' })
        .first()
        .as('followUserButton');
      cy.get('@followUserButton').should('have.text', 'Follow');
      cy.get('@followUserButton').click();
      cy.get('@followUserButton').should('have.text', 'Following');
      cy.get('@followUserButton').click();
      cy.get('@followUserButton').should('have.text', 'Follow');
    });
  });

  it('Follows a tag from an article liquid tag', () => {
    cy.findByRole('main').within(() => {
      cy.findAllByRole('button', { name: 'Follow' })
        .last()
        .as('followUserButton');
      cy.get('@followUserButton').should('have.text', 'Follow');
      cy.get('@followUserButton').click();
      cy.get('@followUserButton').should('have.text', 'Following');
      cy.get('@followUserButton').click();
      cy.get('@followUserButton').should('have.text', 'Follow');
    });
  });
});
