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
    cy.findByRole('button', { name: 'Navigation Menu' }).as(
      'memberDropDownButton',
    );
    cy.get('@memberDropDownButton').trigger('mouseover');
    cy.findByRole('div', { name: 'top-user-dropdown-menu' })
      .as('topUserDropdownMenu')
      .should('be.visible');
    cy.get('@topUserDropdownMenu').within(() => {
      cy.findByRole('link', { name: 'Dashboard' });
      cy.findByRole('link', { name: 'Create Post' });
      cy.findByRole('link', { name: 'Reading list' }).cy.findByRole('link', {
        name: 'Settings',
      });
      cy.findByRole('link', { name: 'Sign Out' });
    });
  });

  it('pressing escape close the User Dropdown menu', () => {
    cy.findByRole('button', { name: 'Navigation Menu' }).as(
      'memberDropDownButton',
    );
    cy.get('@memberDropDownButton').trigger('mouseover');
    cy.findByRole('div', { name: 'top-user-dropdown-menu' })
      .as('topUserDropdownMenu')
      .should('be.visible');
    cy.get('body').type('{esc}');
    cy.get('@topUserDropdownMenu').should('not.be.visible');
  });

  it('close menu on clicking', () => {
    cy.findByRole('button', { name: 'Navigation Menu' }).as(
      'memberDropDownButton',
    );
    cy.get('@memberDropDownButton').trigger('mouseover');
    cy.findByRole('div', { name: 'top-user-dropdown-menu' })
      .as('topUserDropdownMenu')
      .should('be.visible');
    cy.findByRole('link', { name: 'Dashboard' }).click();
    cy.get('@topUserDropdownMenu').should('not.be.visible');
  });

  it('If User profile is already hoverede, clicking on it again will not close it', () => {
    cy.findByRole('button', { name: 'Navigation Menu' }).as(
      'memberDropDownButton',
    );
    cy.get('@memberDropDownButton').trigger('mouseover');
    cy.findByRole('div', { name: 'top-user-dropdown-menu' })
      .as('topUserDropdownMenu')
      .should('be.visible');
    cy.get('@memberDropDownButton').click();
    cy.get('@topUserDropdownMenu').should('be.visible');
  });

  it('hovering out should close menu', () => {
    cy.findByRole('button', { name: 'Navigation Menu' }).as(
      'memberDropDownButton',
    );
    cy.get('@memberDropDownButton').trigger('mouseover');
    cy.findByRole('div', { name: 'top-user-dropdown-menu' })
      .as('topUserDropdownMenu')
      .should('be.visible');
    cy.get('@memberDropDownButton').trigger('mouseout');
    cy.get('@topUserDropdownMenu').should('not.be.visible');
  });

  it('Dropdown menu opened by click will not close on hovering out', () => {
    cy.findByRole('button', { name: 'Navigation Menu' }).as(
      'memberDropDownButton',
    );
    cy.get('@memberDropDownButton').click();
    cy.findByRole('div', { name: 'top-user-dropdown-menu' })
      .as('topUserDropdownMenu')
      .should('be.visible');
    cy.get('@memberDropDownButton').trigger('mouseout');
    cy.get('@topUserDropdownMenu').should('be.visible');
  });
});
