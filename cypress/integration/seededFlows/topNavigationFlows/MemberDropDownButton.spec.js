describe('Member Menu Dropdown', () => {
  beforeEach(() => {
    cy.testSetup();
    cy.fixture('users/articleEditorV1User.json').as('user');

    // Explicitly set the viewport to make sure we're in the full desktop view for these tests
    cy.viewport('macbook-15');

    cy.get('@user').then((user) => {
      cy.loginAndVisit(user, '/');
    });
  });

  it('clicking on User Avatar should show User Dropdown menu', () => {
    cy.findByRole('button', { name: 'Navigation menu' }).click();
    cy.get('#crayons-header__menu__dropdown__list').within(() => {
      cy.findByRole('link', { name: 'Dashboard' });
      cy.findByRole('link', { name: 'Create Post' });
      cy.findByRole('link', { name: 'Reading list' });
      cy.findByRole('link', { name: 'Settings' });
      cy.findByRole('link', { name: 'Sign Out' });
    });
  });

  it('pressing escape should close the User Dropdown menu', () => {
    cy.findByRole('button', { name: 'Navigation menu' }).click();
    cy.findByRole('link', { name: 'Dashboard' })
      .as('dashboard')
      .should('be.visible');
    cy.get('body').type('{esc}');
    cy.get('@dashboard').should('not.be.visible');
  });

  it('close menu on clicking', () => {
    cy.findByRole('button', { name: 'Navigation menu' }).click();
    cy.findByRole('link', { name: 'Dashboard' }).as('dashboard').click();
    cy.get('@dashboard').should('not.be.visible');
  });
});
