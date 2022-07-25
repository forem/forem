describe('Filter user index', () => {
  beforeEach(() => {
    cy.testSetup();
    cy.fixture('users/adminUser.json').as('user');
    // The desktop view allows us to count table rows a bit more easily for validating filter results
    cy.viewport('macbook-16');

    cy.get('@user').then((user) =>
      cy.loginAndVisit(user, '/admin/member_manager/users'),
    );
  });

  const openFiltersModal = () =>
    cy.findByRole('button', { name: 'Filter' }).click();

  it('Collapses previously opened sections when a new section is expanded', () => {
    openFiltersModal();

    cy.getModal().within(() => {
      cy.findAllByText('Member roles').first().click();
      cy.findByRole('group', { name: 'Member roles' }).should('be.visible');

      cy.findAllByText('Status').first().click();
      cy.findByRole('group', { name: 'Status' }).should('be.visible');
      cy.findByRole('group', { name: 'Member roles' }).should('not.be.visible');
    });
  });

  it('Displays and clears applied filters', () => {
    openFiltersModal();

    cy.getModal().within(() => {
      cy.findAllByText('Member roles').first().click();
      cy.findByRole('group', { name: 'Member roles' }).should('be.visible');

      cy.findByRole('checkbox', { name: 'Admin' }).check();
      cy.findByRole('checkbox', { name: 'Super Admin' }).check();

      cy.findAllByText('Organizations').first().click();
      cy.findByRole('group', { name: 'Organizations' }).should('be.visible');
      cy.findByRole('checkbox', { name: 'Bachmanity' }).check();

      cy.findAllByText('Status').first().click();
      cy.findByRole('group', { name: 'Status' }).should('be.visible');
      cy.findByRole('checkbox', { name: 'Trusted' }).check();

      cy.findByRole('button', { name: 'Apply filters' }).click();
    });

    // Verify applied filter pills are visible
    cy.findAllByRole('button', { name: /Remove filter/ }).should(
      'have.length',
      4,
    );

    cy.findByRole('button', { name: 'Remove filter: Admin' }).click();
    // Filter should be removed and pill no longer visible
    cy.findByRole('button', { name: 'Remove filter: Admin' }).should(
      'not.exist',
    );
    cy.findAllByRole('button', { name: /Remove filter/ }).should(
      'have.length',
      3,
    );

    cy.findByRole('button', { name: 'Clear all filters' }).click();
    cy.findByRole('button', { name: 'Clear all filters' }).should('not.exist');
    cy.findByRole('button', { name: /Remove filter/ }).should('not.exist');
    cy.url().should(
      'equal',
      `${Cypress.config().baseUrl}admin/member_manager/users`,
    );
  });

  it('Clears all filters', () => {
    openFiltersModal();
    cy.getModal().within(() => {
      cy.findAllByText('Joining date').first().click();
      cy.findByRole('textbox', { name: /Joined after/ })
        .as('joinStart')
        .type('01/01/2020');
      cy.findByRole('textbox', { name: /Joined before/ })
        .as('joinEnd')
        .type('01/01/2020');

      cy.findAllByText('Member roles').first().click();
      cy.findByRole('group', { name: 'Member roles' }).should('be.visible');
      cy.findByRole('checkbox', { name: 'Super Admin' }).as('role').check();

      cy.findAllByText('Status').first().click();
      cy.findByRole('group', { name: 'Status' }).should('be.visible');
      cy.findByRole('checkbox', { name: 'Trusted' }).as('status').check();

      cy.findAllByText('Organizations').first().click();
      cy.findByRole('group', { name: 'Organizations' }).should('be.visible');
      cy.findByRole('checkbox', { name: 'Bachmanity' })
        .as('organization')
        .check();

      cy.findByRole('button', { name: 'Clear filters' }).click();

      // Check the selected filters are no longer applied
      cy.get('@joinStart').should('have.value', '');
      cy.get('@joinEnd').should('have.value', '');
      cy.get('@role').should('not.be.checked');
      cy.get('@status').should('not.be.checked');
      cy.get('@organization').should('not.be.checked');
    });
  });

  describe('Member roles', () => {
    it('Expands and collapses list of roles', () => {
      openFiltersModal();
      cy.getModal().within(() => {
        cy.findAllByText('Member roles').first().click();
        cy.findByRole('group', { name: 'Member roles' })
          .as('memberRoles')
          .should('be.visible');

        cy.get('@memberRoles')
          .findAllByRole('checkbox')
          .should('have.length', 6);

        cy.findByRole('button', { name: 'See more roles' })
          .as('seeMoreButton')
          .should('have.attr', 'aria-pressed', 'false')
          .click()
          .should('have.attr', 'aria-pressed', 'true');

        cy.get('@memberRoles')
          .findAllByRole('checkbox')
          .should('have.length', 16);

        cy.get('@seeMoreButton')
          .click()
          .should('have.attr', 'aria-pressed', 'false');

        cy.get('@memberRoles')
          .findAllByRole('checkbox')
          .should('have.length', 6);
      });
    });

    it('Filters by a single role', () => {
      openFiltersModal();
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
      openFiltersModal();
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
      openFiltersModal();
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

  describe('Organizations', () => {
    it('filters by organizations', () => {
      openFiltersModal();
      cy.getModal().within(() => {
        cy.findAllByText('Organizations').first().click();
        cy.findByRole('group', { name: 'Organizations' }).should('be.visible');

        cy.findByRole('checkbox', { name: 'Bachmanity' }).check();
        cy.findByRole('checkbox', { name: 'Awesome Org' }).check();
        cy.findByRole('button', { name: 'Apply filters' }).click();
      });

      cy.findAllByRole('row').should('have.length', 4);
    });
  });

  describe('Statuses', () => {
    it('Filters by a single status', () => {
      openFiltersModal();
      cy.getModal().within(() => {
        cy.findAllByText('Status').first().click();
        cy.findByRole('group', { name: 'Status' }).should('be.visible');

        cy.findByRole('checkbox', { name: 'Trusted' }).check();
        cy.findByRole('button', { name: 'Apply filters' }).click();
      });
      // Check expected number of users appear in list
      cy.findAllByRole('row').should('have.length', 4);
    });

    it('Filters by multiple statuses', () => {
      openFiltersModal();
      cy.getModal().within(() => {
        cy.findAllByText('Status').first().click();
        cy.findByRole('group', { name: 'Status' }).should('be.visible');

        cy.findByRole('checkbox', { name: 'Trusted' }).check();
        cy.findByRole('checkbox', { name: 'Suspended' }).check();
        cy.findByRole('button', { name: 'Apply filters' }).click();
      });
      // Check expected number of users appear in list
      cy.findAllByRole('row').should('have.length', 5);
    });
  });

  describe('Joining date', () => {
    it('filters by joining date', () => {
      cy.findByRole('button', { name: 'Filter' }).click();
      cy.getModal().within(() => {
        cy.findAllByText('Joining date').first().click();

        // We need to use a partial name match here, because we can't force the Cypress browser locale to e.g. en-us, and we
        // want to void flake caused by DD/MM/YYYY format vs MM/DD/YYYY
        cy.findByRole('textbox', { name: /Joined after/ }).type('01/01/2020');
        cy.findByRole('textbox', { name: /Joined before/ }).type('01/01/2020');
        cy.findByRole('button', { name: 'Apply filters' }).click();
      });

      // Admin user is deliberately seeded with very early registered date, and should be the only result
      cy.findAllByRole('row').should('have.length', 2);
      cy.findByRole('button', {
        name: 'Remove filter: Joining date',
      }).should('contain', '01/01/2020 - 01/01/2020');
    });

    it('shows community creation in filter pill if no start date selected', () => {
      cy.findByRole('button', { name: 'Filter' }).click();
      cy.getModal().within(() => {
        cy.findAllByText('Joining date').first().click();

        // We need to use a partial name match here, because we can't force the Cypress browser locale to e.g. en-us, and we
        // want to void flake caused by DD/MM/YYYY format vs MM/DD/YYYY
        cy.findByRole('textbox', { name: /Joined before/ }).type('01/01/2020');
        cy.findByRole('button', { name: 'Apply filters' }).click();
      });
      cy.findByRole('button', {
        name: 'Remove filter: Joining date',
      }).should('contain', 'Community creation - 01/01/2020');
    });

    it('shows today in filter pill if no end date selected', () => {
      cy.findByRole('button', { name: 'Filter' }).click();
      cy.getModal().within(() => {
        cy.findAllByText('Joining date').first().click();

        // We need to use a partial name match here, because we can't force the Cypress browser locale to e.g. en-us, and we
        // want to void flake caused by DD/MM/YYYY format vs MM/DD/YYYY
        cy.findByRole('textbox', { name: /Joined after/ }).type('01/01/2020');
        cy.findByRole('button', { name: 'Apply filters' }).click();
      });
      cy.findByRole('button', { name: 'Remove filter: Joining date' }).should(
        'contain',
        '01/01/2020 - Today',
      );
    });
  });

  describe('Multiple filters', () => {
    it('filters by multiple criteria', () => {
      openFiltersModal();
      cy.getModal().within(() => {
        cy.findAllByText('Member roles').first().click();
        cy.findByRole('group', { name: 'Member roles' }).should('be.visible');
        cy.findByRole('checkbox', { name: 'Super Admin' }).check();

        cy.findAllByText('Organizations').first().click();
        cy.findByRole('group', { name: 'Organizations' }).should('be.visible');

        cy.findByRole('checkbox', { name: 'Bachmanity' }).check();
        cy.findByRole('checkbox', { name: 'Awesome Org' }).check();
        cy.findByRole('button', { name: 'Apply filters' }).click();
      });

      cy.findAllByRole('row').should('have.length', 2);
    });
  });
});
