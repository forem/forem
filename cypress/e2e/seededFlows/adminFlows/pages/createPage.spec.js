describe('Create a new page from the admin portal', () => {
  beforeEach(() => {
    cy.testSetup();
    cy.fixture('users/adminUser.json').as('user');
    cy.get('@user').then((user) => {
      cy.loginAndVisit(user, '/admin/customization/pages');
    });
  });

  it('Creates a page with the nav_bar_included template', () => {
    cy.findByRole('link', { name: 'New page' }).click();

    cy.findByRole('textbox', { name: 'Title' }).type('New page with nav bar');
    cy.findByRole('textbox', { name: 'Slug' }).type('test-nav-bar');
    cy.findByRole('textbox', { name: 'Description' }).type('Testing');

    cy.findByRole('combobox', {
      name: "Template Determines the way page's body will be embedded in the layout",
    }).select('nav_bar_included');

    cy.findByRole('textbox', { name: 'Body markdown' }).type('## Hello world');
    cy.findByRole('button', { name: 'Create Page' }).click();

    cy.findByText('Page has been successfully created.').should('exist');
    cy.findByRole('link', { name: 'New page with nav bar' }).click();

    // Check nav bar elements are displayed alongside the entered body markdown
    cy.findByRole('link', { name: 'Nav link 0' });
    cy.findByRole('link', { name: 'Reading List' });
    cy.findByRole('heading', { name: 'Hello world', level: 2 });

    // Check that the nav bar collapses in mobile screen size
    cy.viewport('iphone-x');
    cy.findByRole('link', { name: 'Nav link 0' }).should('not.exist');
    cy.findAllByRole('button', { name: 'Navigation menu' }).first().click();
    cy.findByRole('link', { name: 'Nav link 0' }).should('exist');
  });
});
