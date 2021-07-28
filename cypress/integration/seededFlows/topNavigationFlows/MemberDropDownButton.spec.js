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

  it('hovering on User Avatar should show User Dropdown menu', () => {
    cy.findByRole('button', { name: 'Navigation menu' }).trigger('mouseover');
    cy.get('#crayons-header__menu__dropdown__list').within(() => {
      cy.findByRole('link', { name: 'Dashboard' });
      cy.findByRole('link', { name: 'Create Post' });
      cy.findByRole('link', { name: 'Reading list' });
      cy.findByRole('link', { name: 'Settings' });
      cy.findByRole('link', { name: 'Sign Out' });
    });
  });

  it('pressing escape should close the User Dropdown menu', () => {
    cy.findByRole('button', { name: 'Navigation menu' }).trigger('mouseover');
    cy.findByRole('link', { name: 'Dashboard' })
      .as('dashboard')
      .should('be.visible');
    cy.get('body').type('{esc}');
    cy.get('@dashboard').should('not.be.visible');
  });

  it('close menu on clicking', () => {
    cy.findByRole('button', { name: 'Navigation menu' }).trigger('mouseover');
    cy.findByRole('link', { name: 'Dashboard' }).as('dashboard').click();
    cy.get('@dashboard').should('not.be.visible');
  });

  it('if User profile is already hovered, clicking on it again should not close it', () => {
    cy.findByRole('button', { name: 'Navigation menu' }).as(
      'memberDropDownButton',
    );
    cy.get('@memberDropDownButton').trigger('mouseover');
    cy.findByRole('link', { name: 'Dashboard' }).as('dashboard');
    cy.get('@memberDropDownButton').click();
    cy.get('@dashboard').should('be.visible');
  });

  it('hovering out should close menu', () => {
    cy.findByRole('button', { name: 'Navigation menu' }).as(
      'memberDropDownButton',
    );
    cy.get('@memberDropDownButton').trigger('mouseover');
    cy.findByRole('link', { name: 'Dashboard' }).as('dashboard');
    cy.get('@memberDropDownButton').trigger('mouseout');
    cy.get('@dashboard').should('not.be.visible');
  });

  it('Dropdown menu opened by click will not close on hovering out', () => {
    cy.findByRole('button', { name: 'Navigation menu' }).as(
      'memberDropDownButton',
    );
    cy.get('@memberDropDownButton').trigger('mouseover').click();
    cy.findByRole('link', { name: 'Dashboard' })
      .as('dashboard')
      .should('be.visible');
    cy.get('@memberDropDownButton').trigger('mouseout');
    cy.get('@dashboard').should('be.visible');
  });
});
