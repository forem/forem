describe('Filter user index', () => {
  beforeEach(() => {
    cy.testSetup();
    cy.fixture('users/adminUser.json').as('user');

    cy.enableFeatureFlag('member_index_view')
      .then(() => cy.get('@user'))
      .then((user) => cy.loginAndVisit(user, '/admin/member_manager/users'));
  });

  it('Collapses previously opened sections when a new section is expanded', () => {
    //   TODO: When the V1 Filter input is removed, we can change this to cy.findByRole('button', { name: 'Filter' })
    cy.findAllByRole('button', { name: 'Filter' }).last().click();

    cy.getModal().within(() => {
      cy.findAllByText('Member roles').first().click();
      cy.findByRole('group', { name: 'Member roles' }).should('be.visible');

      cy.findByText('Status').click();
      cy.findByText('Status options').should('be.visible');
      cy.findByRole('group', { name: 'Member roles' }).should('not.be.visible');
    });
  });
});
