function openUserActionsDropdown() {
  // This helper function allows us to use `pipe` to retry commands in case the test runner clicks before the JS has run
  const click = (el) => el.click();

  // This helper function opens and peforms actions within the actions dropdown menu
  cy.findByRole('button', { name: 'User actions: Admin McAdmin' })
    .as('userActionsButton')
    .pipe(click)
    .should('have.attr', 'aria-expanded', 'true');
}

describe('User index view', () => {
  // Helper function for cypress-pipe
  const click = (el) => el.click();

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

    describe('Search', () => {
      // Search controls are initialized async.

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

      it('Clicks through to the Member Detail View', () => {
        cy.findAllByRole('link', { name: 'Admin McAdmin' }).first().click();
        cy.findByRole('heading', { name: 'Admin McAdmin', level: 1 }).should(
          'exist',
        );
      });
    });

    describe('User actions', () => {
      it('Copies user email to clipboard', () => {
        openUserActionsDropdown();

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

    describe('Search', () => {
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

      it('Displays an empty state when no results are returned when searching for a user', () => {
        cy.findByRole('textbox', {
          name: 'Search member by name, username or email',
        }).type('Not a member');

        cy.findByRole('button', { name: 'Search' }).click();

        // Since there aren't any results, the following message should be displayed
        cy.findByText('No members found under these filters.').should('exist');
      });

      it('Clicks through to the Member Detail View', () => {
        cy.findAllByRole('link', { name: 'Admin McAdmin' }).first().click();
        cy.findByRole('heading', { name: 'Admin McAdmin', level: 1 }).should(
          'exist',
        );
      });
    });

    describe('User actions', () => {
      it('Copies user email to clipboard', () => {
        openUserActionsDropdown();

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

      it('Opens the assign role modal', () => {
        openUserActionsDropdown();

        cy.findByRole('button', { name: 'Assign role' }).click();

        cy.getModal().within(() => {
          cy.findByText('Add role').should('be.visible');
          cy.findByText('Add a note to this action:').should('be.visible');
          cy.findByRole('button', {
            name: 'Add',
          }).should('exist');
        });
      });

      it('Opens the add organization modal', () => {
        openUserActionsDropdown();
        cy.findByRole('button', { name: 'Add organization' }).click();

        cy.getModal().within(() => {
          cy.findByText('Organization ID').should('be.visible');
          cy.findByText('Role').should('be.visible');
          cy.findByRole('button', {
            name: 'Add organization',
          }).should('exist');
        });
      });

      it('Opens the adjust credit balance modal', () => {
        openUserActionsDropdown();
        cy.findByRole('button', { name: 'Adjust credit balance' }).click();

        cy.getModal().within(() => {
          cy.findAllByText('Adjust balance').should('be.visible');
          cy.findByText('Add a note to this action:').should('be.visible');
          cy.findByRole('button', {
            name: 'Adjust balance',
          }).should('exist');
        });
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
});
