describe('User index view', () => {
  describe('small screens', () => {
    beforeEach(() => {
      cy.testSetup();
      cy.fixture('users/adminUser.json').as('user');
      cy.get('@user').then((user) => {
        cy.loginUser(user)
          .then(() => cy.enableFeatureFlag('member_index_view'))
          .then(() => cy.visitAndWaitForUserSideEffects('/admin/users'));
      });
      cy.viewport('iphone-x');
    });

    describe('Search and filter', () => {
      // Search and filter controls are initialized async.
      // This helper function allows us to use `pipe` to retry commands in case the test runner clicks before the JS has run
      const click = (el) => el.click();

      it('Searches for a user', () => {
        cy.findByRole('button', { name: 'Expand search' })
          .should('have.attr', 'aria-expanded', 'false')
          .pipe(click)
          .should('have.attr', 'aria-expanded', 'true');

        cy.findByRole('textbox', {
          name: 'Search member by name, username, email, or Twitter/GitHub usernames',
        }).type('Admin McAdmin');

        cy.findByRole('button', { name: 'Search' }).click();

        // Coreect search result should appear
        cy.findByRole('heading', { name: 'Admin McAdmin' }).should('exist');
      });

      it('Filters for a user', () => {
        cy.findByRole('button', { name: 'Expand filter' })
          .should('have.attr', 'aria-expanded', 'false')
          .pipe(click)
          .should('have.attr', 'aria-expanded', 'true');

        cy.findByRole('combobox', { name: 'User role' }).select('super_admin');
        cy.findByRole('button', { name: 'Filter' }).click();

        // Search results should include these two results
        cy.findByRole('heading', { name: 'Admin McAdmin' }).should('exist');
        cy.findByRole('heading', { name: 'Apple Auth Admin User' }).should(
          'exist',
        );
      });

      it('Prevents both search and filter widgets being visible at the same time', () => {
        // Open the filter options
        cy.findByRole('button', { name: 'Expand filter' })
          .as('filterButton')
          .should('have.attr', 'aria-expanded', 'false')
          .pipe(click)
          .should('have.attr', 'aria-expanded', 'true');
        cy.findByRole('combobox').should('exist');

        // Now click to open the search options
        cy.findByRole('button', { name: 'Expand search' })
          .as('searchButton')
          .should('have.attr', 'aria-expanded', 'false')
          .pipe(click)
          .should('have.attr', 'aria-expanded', 'true');
        cy.findByRole('button', { name: 'Search' }).should('exist');

        // verify the filter options have now closed
        cy.get('@filterButton').should('have.attr', 'aria-expanded', 'false');
        cy.findByRole('combobox').should('not.exist');

        // now re-click filter options and check search options have closed
        cy.get('@filterButton').click();
        cy.get('@searchButton').should('have.attr', 'aria-expanded', 'false');
        cy.findByRole('button', { name: 'Search' }).should('not.exist');
      });
    });
  });

  describe('large screens', () => {
    beforeEach(() => {
      cy.testSetup();
      cy.fixture('users/adminUser.json').as('user');
      cy.get('@user').then((user) => {
        cy.loginUser(user)
          .then(() => cy.enableFeatureFlag('member_index_view'))
          .then(() => cy.visitAndWaitForUserSideEffects('/admin/users'));
      });
      cy.viewport('macbook-16');
    });

    describe('Search and filter', () => {
      it('Searches for a user', () => {
        cy.findByRole('textbox', {
          name: 'Search member by name, username, email, or Twitter/GitHub usernames',
        }).type('Admin McAdmin');

        cy.findByRole('button', { name: 'Search' }).click();

        // The table headers consistitute a row, plus one result
        cy.findAllByRole('row').should('have.length', 2);
      });

      it('Filters for a user', () => {
        cy.findByRole('combobox', { name: 'User role' }).select('super_admin');
        cy.findByRole('button', { name: 'Filter' }).click();

        // Table header, 'normal' admin and apple auth admin
        cy.findAllByRole('row').should('have.length', 3);
      });
    });
  });
});
