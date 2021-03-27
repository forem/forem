describe('Comment on an article', () => {
  beforeEach(() => {
    cy.testSetup();
    cy.fixture('users/articleEditorV1User.json').as('user');

    cy.get('@user').then((user) => {
      cy.loginUser(user).then(() => {
        cy.createArticle({
          title: 'Test Article',
          tags: ['beginner', 'ruby', 'go'],
          content: `This is a test article's contents.`,
          published: true,
        }).then((response) => {
          cy.visit(response.body.current_state_path);
        });
      });
    });
  });

  it('should add a comment', () => {
    cy.findByRole('main')
      .as('main')
      .findByRole('textbox', { name: /^Add a comment to the discussion$/i })
      .focus() // Focus activates the Submit button and mini toolbar below a comment textbox
      .type('this is a comment');

    cy.get('@main')
      .findByRole('textbox', { name: /^Add a comment to the discussion$/i })
      .should('have.value', 'this is a comment');

    cy.get('@main')
      .findByRole('button', { name: /^Submit$/i })
      .click();

    // Comment was saved so the new comment textbox should be empty.
    cy.get('@main')
      .findByRole('textbox', { name: /^Add a comment to the discussion$/i })
      .should('have.value', '');

    cy.get('@main').findByText(/^this is a comment$/i);
    cy.get('@main').findByRole('heading', { name: 'Discussion (1)' });
  });

  it('should add a comment from a canned response', () => {
    cy.createCannedResponse({
      title: 'test canned response',
      content: 'This is a canned response',
    }).then((_response) => {
      cy.findByRole('main')
        .as('main')
        .findByRole('textbox', { name: /^Add a comment to the discussion$/i })
        .focus(); // Focus activates the Submit button and mini toolbar below a comment textbox

      cy.get('@main')
        .findByRole('button', { name: /^Use a response template$/i })
        .click();

      cy.get('@main')
        .findByRole('button', { name: /^Insert$/i })
        .click();

      cy.get('@main')
        .findByRole('textbox', { name: /^Add a comment to the discussion$/i })
        .should('have.value', 'This is a canned response');

      cy.get('@main')
        .findByRole('button', { name: /^Submit$/i })
        .click();

      // Comment was saved so the new comment textbox should be empty.
      cy.get('@main')
        .findAllByLabelText('Add a comment to the discussion')
        .should('be.visible')
        .should('have.value', '');

      // TODO: Fix query
      // Can't get this query working for some reason.
      // cy.get('@main').findByText(/^This is a canned response$/i);

      // This query works, but it's not the approach we want.
      cy.get('@main')
        .get('.comment__body > p')
        .should('have.text', 'This is a canned response');

      cy.get('@main').findByRole('heading', { name: 'Discussion (1)' });
    });
  });
});
