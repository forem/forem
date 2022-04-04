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
    // TODO: If we go with the approach in this commit, then we should test the
    // "Create Button" that's on the nav bar but not in the drop down.

    cy.findByRole('button', { name: 'Navigation menu' }).as('menuButton');
    cy.get('@menuButton')
      .should('have.attr', 'aria-expanded', 'false')
      .click()
      .should('have.attr', 'aria-expanded', 'true');

    cy.findByRole('link', { name: 'Create Post' }).should('not.exist');
  });
});
