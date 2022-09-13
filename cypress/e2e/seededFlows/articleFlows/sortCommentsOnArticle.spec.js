describe('Sort Comments in an Article', () => {
  beforeEach(() => {
    cy.testSetup();
    cy.viewport('macbook-16');
    cy.fixture('users/articleEditorV1User.json').as('user');

    cy.get('@user').then((user) => {
      cy.loginAndVisit(user, '/admin_mcadmin/test-article-slug');
      // Make sure the page has loaded
      cy.findByRole('heading', { name: 'Test article' });
    });
  });

  it('clicking on sort comments button should open and close dropdown menu', () => {
    cy.findByRole('button', { name: 'Sort comments' })
      .should('have.attr', 'aria-expanded', 'false')
      .click()
      .should('have.attr', 'aria-expanded', 'true');

    cy.findByRole('navigation', { name: 'Sort discussion:' }).within(() => {
      cy.findByRole('link', { name: /Top/ });
      cy.findByRole('link', { name: /Oldest/ });
      cy.findByRole('link', { name: /Latest/ });
    });
  });

  it('by default shows top comments', () => {
    cy.findByRole('button', { name: 'Sort comments' }).click();

    cy.findByRole('navigation', { name: 'Sort discussion:' }).within(() => {
      cy.findByRole('link', {
        name: /Top/,
      }).should('have.attr', 'aria-current', 'page');

      cy.findByRole('link', {
        name: /Top/,
      }).should('have.focus');
    });

    cy.findByRole('heading', { name: 'Top comments (1)' }).should('exist');
  });

  it('should navigate to latest', () => {
    cy.findByRole('button', { name: 'Sort comments' }).click();

    cy.findByRole('navigation', { name: 'Sort discussion:' }).within(() => {
      cy.findByRole('link', {
        name: /Latest/,
      }).click();
    });

    cy.url().should('contain', '?comments_sort=latest');
    cy.findByRole('heading', { name: 'Latest comments (1)' }).should('exist');

    cy.findByRole('button', { name: 'Sort comments' }).click();

    cy.findByRole('navigation', { name: 'Sort discussion:' }).within(() => {
      cy.findByRole('link', {
        name: /Latest/,
      }).should('have.attr', 'aria-current', 'page');
    });
  });

  it('should navigate to oldest', () => {
    cy.findByRole('button', { name: 'Sort comments' }).click();

    cy.findByRole('navigation', { name: 'Sort discussion:' }).within(() => {
      cy.findByRole('link', {
        name: /Oldest/,
      }).click();
    });

    cy.url().should('contain', '?comments_sort=oldest');
    cy.findByRole('heading', { name: 'Oldest comments (1)' }).should('exist');

    cy.findByRole('button', { name: 'Sort comments' }).click();

    cy.findByRole('navigation', { name: 'Sort discussion:' }).within(() => {
      cy.findByRole('link', {
        name: /Oldest/,
      }).should('have.attr', 'aria-current', 'page');
    });
  });
});
