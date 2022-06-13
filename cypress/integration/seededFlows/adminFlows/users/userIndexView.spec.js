describe('User index view', () => {
  describe('small screens', () => {
    beforeEach(() => {
      cy.testSetup();
      cy.fixture('users/adminUser.json').as('user');
      cy.get('@user').then((user) => {
        cy.loginAndVisit(user, '/admin/member_manager/users');
      });
      cy.viewport('iphone-x');
    });

    it('Displays expected data', () => {
      // Find the specific article for a user, and check data inside of it
      cy.findByRole('heading', { name: 'Many orgs user' })
        .closest('article')
        .within(() => {
          cy.findByText('@many_orgs_user').should('exist');
          cy.findAllByRole('link', { name: 'Many orgs user' }).should(
            'have.length',
            2,
          );
          cy.findByAltText('Many orgs user').should('exist');
          cy.findAllByText('Good standing').should('exist');
          cy.findByText('Last activity').should('exist');
          cy.findByText('Joined on').should('exist');
          cy.findByRole('figure').findByText('+ 1').should('exist');
        });
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
          name: 'Search member by name, username or email',
        }).type('Admin McAdmin');

        cy.findByRole('button', { name: 'Search' }).click();

        // Correct search result should appear
        cy.findByRole('heading', { name: 'Admin McAdmin' }).should('exist');
      });

      it('Filters for a user', () => {
        cy.findByRole('button', { name: 'Expand filter' })
          .should('have.attr', 'aria-expanded', 'false')
          .pipe(click)
          .should('have.attr', 'aria-expanded', 'true');

        cy.findByRole('combobox', { name: 'User role' }).select('super_admin');
        cy.findByRole('button', { name: 'Filter' }).click();

        // Filter results should include these two results
        cy.findByRole('heading', { name: 'Admin McAdmin' }).should('exist');
        cy.findAllByText('Apple Auth Admin User').should('exist');
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

        // Verify the filter options have now closed
        cy.get('@filterButton').should('have.attr', 'aria-expanded', 'false');
        cy.findByRole('combobox').should('not.exist');

        // Now re-click filter options and check search options have closed
        cy.get('@filterButton').click();
        cy.get('@searchButton').should('have.attr', 'aria-expanded', 'false');
        cy.findByRole('button', { name: 'Search' }).should('not.exist');
      });

      it('indicates filter is applied if filter options are collapsed', () => {
        // Choose a filter
        cy.findByRole('button', { name: 'Expand filter' })
          .as('filterButton')
          .should('have.attr', 'aria-expanded', 'false')
          .pipe(click)
          .should('have.attr', 'aria-expanded', 'true');
        cy.findByRole('combobox').select('trusted');
        // Indicator should not be shown while open
        cy.get('@filterButton')
          .findByTestId('search-indicator')
          .should('not.be.visible');

        // Collapse the filter field; indicator should now be shown
        cy.get('@filterButton')
          .click()
          .should('have.attr', 'aria-expanded', 'false');
        cy.get('@filterButton')
          .findByTestId('search-indicator')
          .should('be.visible');
      });

      it('indicates a search term is applied if search options are collapsed', () => {
        // Enter some text in search term
        cy.findByRole('button', { name: 'Expand search' })
          .as('searchButton')
          .should('have.attr', 'aria-expanded', 'false')
          .pipe(click)
          .should('have.attr', 'aria-expanded', 'true');
        cy.findByRole('textbox', {
          name: 'Search member by name, username or email',
        })
          .clear()
          .type('something');
        // Indicator should not be shown while open
        cy.get('@searchButton')
          .findByTestId('search-indicator')
          .should('not.be.visible');

        // Collapse the filter field; indicator should now be shown
        cy.get('@searchButton')
          .click()
          .should('have.attr', 'aria-expanded', 'false');
        cy.get('@searchButton')
          .findByTestId('search-indicator')
          .should('be.visible');
      });

      it(`Clicks through to the Member Detail View`, () => {
        cy.findAllByRole('link', { name: 'Admin McAdmin' }).first().click();
        cy.url().should('contain', '/admin/member_manager/users/1');
      });
    });

    describe('User actions', () => {
      it('Copies user email to clipboard', () => {
        // Helper function for cypress-pipe
        const click = (el) => el.click();

        cy.findByRole('button', { name: 'User actions: Admin McAdmin' })
          .as('userActionsButton')
          .pipe(click)
          .should('have.attr', 'aria-expanded', 'true');

        cy.findByRole('button', { name: 'Copy email address' }).click();

        // Snackbar should appear with confirmation, and dropdown should close
        cy.findByTestId('snackbar')
          .findByText('Copied to clipboard')
          .should('exist');
        cy.get('@userActionsButton')
          .should('have.attr', 'aria-expanded', 'false')
          .should('have.focus');

        // Check the correct text is on the clipboard
        cy.window()
          .its('navigator.clipboard')
          .invoke('readText')
          .should('equal', 'admin@forem.local');
      });
    });

    describe('Empty state', () => {
      // Search and filter controls are initialized async.
      // This helper function allows us to use `pipe` to retry commands in case the test runner clicks before the JS has run
      const click = (el) => el.click();

      it('Displays an empty state when no results are returned when searching for a user', () => {
        cy.findByRole('button', { name: 'Expand search' })
          .should('have.attr', 'aria-expanded', 'false')
          .pipe(click)
          .should('have.attr', 'aria-expanded', 'true');

        cy.findByRole('textbox', {
          name: 'Search member by name, username or email',
        }).type('Not a member');

        cy.findByRole('button', { name: 'Search' }).click();

        // Since there aren't any results, the following message should be displayed
        cy.findByText('No members found under these filters.').should('exist');
      });

      it('Displays an empty state when no results are returned when filtering for a user', () => {
        cy.findByRole('button', { name: 'Expand filter' })
          .should('have.attr', 'aria-expanded', 'false')
          .pipe(click)
          .should('have.attr', 'aria-expanded', 'true');

        cy.findByRole('combobox', { name: 'User role' }).select(
          'codeland_admin',
        );
        cy.findByRole('button', { name: 'Filter' }).click();

        // Since there aren't any results, the following message should be displayed
        cy.findByText('No members found under these filters.').should('exist');
      });
    });
  });

  describe('large screens', () => {
    beforeEach(() => {
      cy.testSetup();
      cy.fixture('users/adminUser.json').as('user');
      cy.get('@user').then((user) => {
        cy.loginAndVisit(user, '/admin/member_manager/users');
      });
      cy.viewport('macbook-16');
    });

    it('Displays expected data', () => {
      // Find the specific table row for a user, and check data inside of it
      cy.findByRole('table')
        .findAllByRole('link', { name: 'Many orgs user' })
        .first()
        .closest('tr')
        .within(() => {
          cy.findByText('@many_orgs_user').should('exist');
          cy.findAllByRole('link', { name: 'Many orgs user' }).should(
            'have.length',
            2,
          );
          cy.findByAltText('Many orgs user').should('exist');
          cy.findAllByText('Good standing').should('exist');
          cy.findByRole('figure').findByText('+ 1').should('exist');
        });
    });

    describe('Search and filter', () => {
      it('Searches for a user', () => {
        cy.findByRole('textbox', {
          name: 'Search member by name, username or email',
        }).type('Admin McAdmin');

        cy.findByRole('button', { name: 'Search' }).click();

        // Correct search result should appear
        cy.findByRole('heading', { name: 'Admin McAdmin' }).should('exist');

        // The table headers consistitute a row, plus one result
        cy.findAllByRole('row').should('have.length', 2);
      });

      it('Filters for a user', () => {
        cy.findByRole('combobox', { name: 'User role' }).select('super_admin');
        cy.findByRole('button', { name: 'Filter' }).click();

        // Filter results should include these two results
        cy.findByRole('heading', { name: 'Admin McAdmin' }).should('exist');
        cy.findAllByText('Apple Auth Admin User').should('exist');

        // Table header, 'normal' admin and apple auth admin
        cy.findAllByRole('row').should('have.length', 3);
      });

      it(`Clicks through to the Member Detail View`, () => {
        cy.findAllByRole('link', { name: 'Admin McAdmin' }).first().click();
        cy.url().should('contain', '/admin/member_manager/users/1');
      });
    });

    describe('Empty state', () => {
      it('Displays an empty state when no results are returned when searching for a user', () => {
        cy.findByRole('textbox', {
          name: 'Search member by name, username or email',
        }).type('Not a member');

        cy.findByRole('button', { name: 'Search' }).click();

        // Since there aren't any results, the following message should be displayed
        cy.findByText('No members found under these filters.').should('exist');
      });

      it('Displays an empty state when no results are returned when filtering for a user', () => {
        cy.findByRole('combobox', { name: 'User role' }).select(
          'codeland_admin',
        );
        cy.findByRole('button', { name: 'Filter' }).click();

        // Since there aren't any results, the following message should be displayed
        cy.findByText('No members found under these filters.').should('exist');
      });
    });

    describe('User actions', () => {
      it('Copies user email to clipboard', () => {
        // Helper function for cypress-pipe
        const click = (el) => el.click();

        cy.findByRole('button', { name: 'User actions: Admin McAdmin' })
          .as('userActionsButton')
          .pipe(click)
          .should('have.attr', 'aria-expanded', 'true');

        cy.findByRole('button', { name: 'Copy email address' }).click();

        // Snackbar should appear with confirmation, and dropdown should close
        cy.findByTestId('snackbar')
          .findByText('Copied to clipboard')
          .should('exist');
        cy.get('@userActionsButton')
          .should('have.attr', 'aria-expanded', 'false')
          .should('have.focus');

        // Check the correct text is on the clipboard
        cy.window()
          .its('navigator.clipboard')
          .invoke('readText')
          .should('equal', 'admin@forem.local');
      });
    });

    describe('Export CSV', () => {
      it('Contains a link to download member data', () => {
        cy.findByRole('button', { name: 'Download member data' }).click();

        cy.getModal().within(() => {
          cy.findByText(
            'Your data will be downloaded as a Comma Separated Values (.csv) file.',
          ).should('be.visible');
          cy.findByText(
            'Values listed are Name, Username, Email address, Status, Joining date, Last activity, and Organizations.',
          ).should('be.visible');
          cy.findByRole('link', {
            name: 'Download',
            href: '/admin/member_manager/users/export.csv',
          }).should('exist');
        });
      });
    });
  });

  describe('User index view with the member_index_view feature flag enabled', () => {
    describe('small screens', () => {
      beforeEach(() => {
        cy.testSetup();
        cy.fixture('users/adminUser.json').as('user');
        cy.enableFeatureFlag('member_index_view')
          .then(() => cy.get('@user'))
          .then((user) =>
            cy.loginAndVisit(user, '/admin/member_manager/users'),
          );
        cy.viewport('iphone-x');
      });

      describe('User actions', () => {
        it('Opens the assign role modal', () => {
          cy.enableFeatureFlag('member_index_view');
          // Helper function for cypress-pipe
          const click = (el) => el.click();

          cy.findByRole('button', { name: 'User actions: Admin McAdmin' })
            .as('userActionsButton')
            .pipe(click)
            .should('have.attr', 'aria-expanded', 'true');

          cy.findByRole('button', { name: 'Assign role' }).click();

          cy.getModal().within(() => {
            cy.findByText('Add role').should('be.visible');
            cy.findByText('Add a note to this action:').should('be.visible');
            cy.findByRole('button', {
              name: 'Add',
            }).should('exist');
          });
        });
      });

      describe('large screens', () => {
        beforeEach(() => {
          cy.testSetup();
          cy.fixture('users/adminUser.json').as('user');
          cy.enableFeatureFlag('member_index_view')
            .then(() => cy.get('@user'))
            .then((user) =>
              cy.loginAndVisit(user, '/admin/member_manager/users'),
            );
          cy.viewport('macbook-16');
        });

        describe('User actions', () => {
          it('Opens the assign role modal', () => {
            cy.enableFeatureFlag('member_index_view');
            // Helper function for cypress-pipe
            const click = (el) => el.click();

            cy.findByRole('button', { name: 'User actions: Admin McAdmin' })
              .as('userActionsButton')
              .pipe(click)
              .should('have.attr', 'aria-expanded', 'true');

            cy.findByRole('button', { name: 'Assign role' }).click();

            cy.getModal().within(() => {
              cy.findByText('Add role').should('be.visible');
              cy.findByText('Add a note to this action:').should('be.visible');
              cy.findByRole('button', {
                name: 'Add',
              }).should('exist');
            });
          });
        });
      });
    });
  });
});
