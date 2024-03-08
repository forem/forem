/**
   This is to verify visibility of buttons.  The authorization tests are
   asserted in their corresponding policy tests.
*/
describe('Limit Post Creation to Admins', () => {
  beforeEach(() => {
    cy.testSetup();
    cy.fixture('users/articleEditorV1User.json').as('user');
    cy.enableFeatureFlag('limit_post_creation_to_admins');
    cy.get('@user').then((user) => {
      cy.loginAndVisit(user, '/');
    });
  });

  it('clicking on User Avatar should open User Dropdown menu and no Create Post is visible', () => {
    cy.findByRole('button', { name: 'Navigation menu' }).as('menuButton');
    cy.get('@menuButton').should('have.attr', 'aria-expanded', 'false');
    cy.get('@menuButton').click();
    cy.get('@menuButton').should('have.attr', 'aria-expanded', 'true');

    cy.findByRole('link', {
      name: 'Article Editor v1 User @article_editor_v1_user',
    }).should('exist');

    // The "Create Post" button either outside of the drop-down nor inside
    cy.findByRole('link', { name: 'Create Post' }).should('not.exist');
  });
});
