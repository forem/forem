describe('Pin an article - Anonymous user', () => {
  beforeEach(() => {
    cy.testSetup();

    cy.visit('/');
  });

  it('should not see the Pin Post button', () => {
    cy.findByRole('heading', { name: 'Test article' }).click();

    cy.findByRole('main')
      .findByRole('button', { name: 'Pin Post' })
      .should('not.exist');
  });
});

describe('Pin an article - Non admin user', () => {
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

  it('should not see the Pin Post button', () => {
    cy.findByRole('main')
      .findByRole('button', { name: 'Pin Post' })
      .should('not.exist');
  });
});

describe('Pin an article - Admin User', () => {
  beforeEach(() => {
    cy.testSetup();
    cy.fixture('users/adminUser.json').as('user');

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

  it('should pin a post', () => {
    cy.findByRole('main').within(() => {
      cy.findByRole('button', { name: 'Pin Post' }).click();

      // check the button has changed to "Unpin Post"
      cy.findByRole('button', { name: 'Unpin Post' });
    });

    cy.visit('/');

    cy.findByRole('main').findByTestId('pinned-article').should('be.visible');
  });

  it('should unpin a post', () => {
    cy.findByRole('main').within(() => {
      cy.findByRole('button', { name: 'Pin Post' }).click();
      cy.findByRole('button', { name: 'Unpin Post' }).click();
      cy.findByRole('button', { name: 'Pin Post' });
    });

    cy.visit('/');

    cy.findByRole('main').findByTestId('pinned-article').should('not.exist');
  });

  it('should not add the "Pin Post" button to the non currently pinned article', () => {
    cy.findByRole('main').findByRole('button', { name: 'Pin Post' }).click();

    cy.createArticle({
      title: 'Test Article 2',
      tags: ['beginner', 'ruby', 'go'],
      content: `This is a test article's contents.`,
      published: true,
    }).then((response) => {
      cy.visit(response.body.current_state_path);
    });

    cy.findByRole('main')
      .findByRole('button', { name: 'Pin Post' })
      .should('not.exist');
  });
});
