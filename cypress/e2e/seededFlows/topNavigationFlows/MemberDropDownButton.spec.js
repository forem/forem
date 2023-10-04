describe('Member Menu Dropdown', () => {
  beforeEach(() => {
    cy.testSetup();
    cy.fixture('users/articleEditorV1User.json').as('user');

    cy.get('@user').then((user) => {
      cy.loginAndVisit(user, '/');
    });
  });

  it('clicking on User Avatar should open and close User Dropdown menu', () => {
    cy.findByRole('button', { name: 'Navigation menu' }).as('menuButton');
    cy.get('@menuButton').should('have.attr', 'aria-expanded', 'false');
    cy.get('@menuButton').click();
    cy.get('@menuButton').should('have.attr', 'aria-expanded', 'true');

    cy.get('#crayons-header__menu__dropdown__list').within(() => {
      cy.findByRole('link', {
        name: 'Article Editor v1 User @article_editor_v1_user',
      }).should('have.focus');

      cy.findByRole('link', { name: 'Dashboard' });
      cy.findByRole('link', { name: 'Create Post' });
      cy.findByRole('link', { name: 'Reading list' });
      cy.findByRole('link', { name: 'Settings' });
      cy.findByRole('link', { name: 'Sign Out' });
    });

    cy.get('@menuButton').click();
    cy.get('@menuButton').should('have.attr', 'aria-expanded', 'false');
    cy.get('@menuButton').should('have.focus');
  });

  it('pressing escape should close the User Dropdown menu', () => {
    cy.findByRole('button', { name: 'Navigation menu' }).as('menuButton');
    cy.get('@menuButton').should('have.attr', 'aria-expanded', 'false');
    cy.get('@menuButton').click();
    cy.get('@menuButton').should('have.attr', 'aria-expanded', 'true');

    cy.findByRole('link', { name: 'Dashboard' })
      .as('dashboard')
      .should('be.visible');

    cy.get('body').type('{esc}');
    cy.get('@dashboard').should('not.be.visible');
    cy.get('@menuButton').should('have.attr', 'aria-expanded', 'false');
  });

  it('closes menu on click outside', () => {
    cy.findByRole('button', { name: 'Navigation menu' }).as('menuButton');
    cy.get('@menuButton').should('have.attr', 'aria-expanded', 'false');
    cy.get('@menuButton').click();
    cy.get('@menuButton').should('have.attr', 'aria-expanded', 'true');

    cy.findByRole('link', { name: 'Dashboard' }).as('dashboard');
    cy.get('@dashboard').should('be.visible');

    cy.get('body').click('topLeft');

    cy.get('@dashboard').should('not.be.visible');
    cy.get('@menuButton').should('have.attr', 'aria-expanded', 'false');
  });

  it('closes menu on selecting a link from the menu', () => {
    cy.findByRole('button', { name: 'Navigation menu' }).click();
    cy.findByRole('link', { name: 'Dashboard' }).as('dashboard').click();
    cy.get('@dashboard').should('not.be.visible');
  });
});
