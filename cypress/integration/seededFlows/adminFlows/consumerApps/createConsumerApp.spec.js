describe('Consumer Apps', () => {
  beforeEach(() => {
    cy.testSetup();
    cy.fixture('users/adminUser.json').as('user');

    cy.get('@user').then((user) => {
      cy.loginUser(user);
      cy.visit('/admin/apps/consumer_apps');
    });
  });

  it('creates a new iOS Consumer App', () => {
    const test_app_bundle = 'com.app.bundle';
    cy.get('.crayons-btn').contains('New Consumer App').click();
    cy.get('#new_consumer_app').as('consumerAppForm');
    cy.get('@consumerAppForm').find('#app_bundle').type(test_app_bundle);
    cy.get('@consumerAppForm').find('#platform').select('iOS');

    // iOS apps need to provide the option to add a Team ID value
    cy.get('@consumerAppForm').find('#team_id').should('be.visible');
    cy.get('@consumerAppForm').find('#team_id').type('ABC123');
    cy.get('@consumerAppForm')
      .get('.crayons-btn')
      .contains('Create Consumer App')
      .click();

    cy.findByText(`${test_app_bundle} has been created!`).should('be.visible');
  });

  it('creates a new Android Consumer App', () => {
    const test_app_bundle = 'com.app.bundle';
    cy.get('.crayons-btn').contains('New Consumer App').click();
    cy.get('#new_consumer_app').as('consumerAppForm');
    cy.get('@consumerAppForm').find('#app_bundle').type(test_app_bundle);
    cy.get('@consumerAppForm').find('#platform').select('Android');

    // Android apps don't need a Team ID value
    cy.get('@consumerAppForm').find('#team_id').should('not.be.visible');
    cy.get('@consumerAppForm')
      .get('.crayons-btn')
      .contains('Create Consumer App')
      .click();

    cy.findByText(`${test_app_bundle} has been created!`).should('be.visible');
  });
});
