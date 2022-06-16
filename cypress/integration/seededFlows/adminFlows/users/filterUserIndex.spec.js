describe('Filter user index', () => {
  beforeEach(() => {
    cy.testSetup();
    cy.fixture('users/adminUser.json').as('user');
    // The desktop view allows us to count table rows a bit more easily for validating filter results
    cy.viewport('macbook-16');

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

  describe('Member roles', () => {
    it('Expands and collapses list of roles', () => {
      cy.findAllByRole('button', { name: 'Filter' }).last().click();
      cy.getModal().within(() => {
        cy.findAllByText('Member roles').first().click();
        cy.findByRole('group', { name: 'Member roles' }).should('be.visible');

        cy.findAllByRole('checkbox').should('have.length', 6);
        cy.findByRole('button', { name: 'See more roles' })
          .as('seeMoreButton')
          .should('have.attr', 'aria-pressed', 'false')
          .click()
          .should('have.attr', 'aria-pressed', 'true');

        cy.findAllByRole('checkbox').should('have.length', 16);
        cy.get('@seeMoreButton')
          .click()
          .should('have.attr', 'aria-pressed', 'false');
        cy.findAllByRole('checkbox').should('have.length', 6);
      });
    });

    it('Filters by a single role', () => {
      cy.findAllByRole('button', { name: 'Filter' }).last().click();
      cy.getModal().within(() => {
        cy.findAllByText('Member roles').first().click();
        cy.findByRole('group', { name: 'Member roles' }).should('be.visible');

        cy.findByRole('checkbox', { name: 'Super Admin' }).check();
        cy.findByRole('button', { name: 'Apply filters' }).click();
      });
      // Check expected number of users appear in list
      cy.findAllByRole('row').should('have.length', 3);
    });

    it('Filters by multiple roles', () => {
      cy.findAllByRole('button', { name: 'Filter' }).last().click();
      cy.getModal().within(() => {
        cy.findAllByText('Member roles').first().click();
        cy.findByRole('group', { name: 'Member roles' }).should('be.visible');

        cy.findByRole('checkbox', { name: 'Super Admin' }).check();
        cy.findByRole('checkbox', { name: 'Tech Admin' }).check();
        cy.findByRole('button', { name: 'Apply filters' }).click();
      });
      // Check expected number of users appear in list
      cy.findAllByRole('row').should('have.length', 4);
    });

    it('Clears filters', () => {
      cy.findAllByRole('button', { name: 'Filter' }).last().click();
      cy.getModal().within(() => {
        cy.findAllByText('Member roles').first().click();
        cy.findByRole('group', { name: 'Member roles' }).should('be.visible');

        // Initially, the clear filters button should not be visible
        cy.findByRole('button', { name: 'Clear member roles filter' }).should(
          'not.exist',
        );

        cy.findByRole('checkbox', { name: 'Super Admin' })
          .as('superAdmin')
          .check();

        // Clear button should now be available
        cy.findByRole('button', { name: 'Clear member roles filter' })
          .should('exist')
          .click();

        cy.get('@superAdmin').should('not.be.checked');
        cy.findByRole('button', { name: 'Clear member roles filter' }).should(
          'not.exist',
        );
      });
    });
  });
});
