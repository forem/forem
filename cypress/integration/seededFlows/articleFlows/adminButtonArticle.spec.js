describe('Admin button on article - Anonymous user', () => {
  beforeEach(() => {
    cy.testSetup();
    cy.visit('/admin_mcadmin/test-article-slug');
  });

  it('should not see the Admin button', () => {
    cy.findAllByRole('heading', { name: 'Test article' }).first().click();

    cy.findByRole('main')
      .findByRole('button', { name: 'Admin' })
      .should('not.exist');
  });
});

describe('Admin button on article - Non admin user', () => {
  beforeEach(() => {
    cy.testSetup();
    cy.fixture('users/articleEditorV1User.json').as('user');

    // Responses from these requests are not required for this test, and are stubbed to prevent responses interfering with subsequent tests
    cy.intercept('/reactions?article**', {
      body: {
        current_user: { id: '' },
        reactions: [],
        article_reaction_counts: [],
      },
    });
    cy.intercept('/reactions?commentable**', {
      body: {
        current_user: { id: '' },
        reactions: [],
        public_reaction_counts: [],
      },
    });
    cy.intercept('/follows**', {});

    cy.get('@user').then((user) => {
      cy.loginUser(user).then(() => {
        cy.visit('/admin_mcadmin/test-article-slug');
      });
    });
  });

  it('should not see the Admin button', () => {
    cy.findByRole('main')
      .findByRole('button', { name: 'Admin' })
      .should('not.exist');
  });
});

describe('Admin User viewing article', () => {
  beforeEach(() => {
    cy.testSetup();
    cy.fixture('users/adminUser.json').as('user');

    cy.get('@user').then((user) => {
      cy.loginUser(user).then(() => {
        cy.visit('/admin_mcadmin/test-article-slug');
      });
    });
  });

  it('should see the admin button', () => {
    cy.findByRole('main').within(() => {
      cy.findAllByRole('link', { name: 'Admin' })
        .first()
        .should('have.attr', 'href')
        .and('contains', '/admin/content_manager/articles');
    });
  });
});
