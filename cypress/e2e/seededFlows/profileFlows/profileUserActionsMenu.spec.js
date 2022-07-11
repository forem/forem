describe('Profile User Actions Menu', () => {
  // We complete logged out tests first, as unfinished network requests relating to logged-in users can cause unexpected failures
  // See: https://github.com/forem/forem/issues/13988
  describe('Logged out users', () => {
    beforeEach(() => {
      cy.testSetup();
    });

    it('should show a dropdown menu with only the Report Abuse link when the user is not logged in', () => {
      cy.visit('/article_editor_v1_user');
      // Make sure the dropdown has initialized
      cy.get('[data-dropdown-initialized]');

      cy.findByRole('button', { name: 'User actions' }).click();

      cy.findByRole('link', { name: 'Report Abuse' }).should('have.focus');

      cy.findByRole('link', { name: 'Block @article_editor_v1_user' }).should(
        'not.exist',
      );
      cy.findByRole('link', { name: 'Flag @article_editor_v1_user' }).should(
        'not.exist',
      );
    });
  });

  describe('Logged in users', () => {
    beforeEach(() => {
      cy.testSetup();
      cy.fixture('users/adminUser.json').as('user');

      cy.get('@user').then((user) => {
        cy.loginAndVisit(user, '/');
      });
    });

    it("should show a dropdown menu when a user views another user's profile", () => {
      cy.visit('/article_editor_v1_user');

      // Make sure the dropdown has initialized
      cy.get('[data-dropdown-initialized]');

      cy.findByRole('button', { name: 'User actions' }).as('dropdownButton');
      cy.get('@dropdownButton').click();
      cy.findByRole('link', { name: 'Block @article_editor_v1_user' }).should(
        'have.focus',
      );
      cy.findByRole('link', { name: 'Flag @article_editor_v1_user' });
      cy.findByRole('link', { name: 'Report Abuse' });

      // Check the menu can be closed by click
      cy.get('@dropdownButton').click();
      cy.findByRole('link', { name: 'Block @article_editor_v1_user' }).should(
        'not.exist',
      );

      // Check the menu can be closed by escape press
      cy.get('@dropdownButton').click();
      cy.findByRole('link', { name: 'Block @article_editor_v1_user' });
      cy.get('body').type('{esc}');
      cy.findByRole('link', { name: 'Block @article_editor_v1_user' }).should(
        'not.exist',
      );
      cy.get('@dropdownButton').should('have.focus');
    });

    it('should not show a dropdown menu when a user views their own profile', () => {
      cy.visit('/admin_mcadmin');
      cy.findByRole('button', { name: 'User actions' }).should('not.exist');
    });

    it('should block and unblock a user', () => {
      // Always accept the confirmation that pops up
      cy.on('window:confirm', () => true);

      cy.visit('/article_editor_v1_user');

      // Make sure the dropdown has initialized
      cy.get('[data-dropdown-initialized]');

      cy.findByRole('button', { name: 'User actions' }).click();
      cy.findByRole('link', { name: 'Block @article_editor_v1_user' }).click();

      // Check that the menu option has updated, and unblock user
      cy.findByRole('link', { name: 'Block @article_editor_v1_user' }).should(
        'not.exist',
      );
      cy.findByRole('link', { name: 'Unblock' }).click();

      cy.findByRole('link', { name: 'Unblock' }).should('not.exist');
      cy.findByRole('link', { name: 'Block' });
    });

    it('should flag and unflag a user', () => {
      // Always accept the confirmation that pops up
      cy.on('window:confirm', () => true);

      cy.visit('/article_editor_v1_user');

      // Make sure the dropdown has initialized
      cy.get('[data-dropdown-initialized]');

      cy.findByRole('button', { name: 'User actions' }).click();
      cy.findByRole('link', { name: 'Flag @article_editor_v1_user' }).click();

      // Check that the menu option has updated
      cy.findByRole('link', { name: 'Flag @article_editor_v1_user' }).should(
        'not.exist',
      );
      cy.findByRole('link', { name: 'Unflag @article_editor_v1_user' }).click();

      // Check that the menu option has updated
      cy.findByRole('link', { name: 'Unflag @article_editor_v1_user' }).should(
        'not.exist',
      );
      cy.findByRole('link', { name: 'Flag @article_editor_v1_user' });
    });

    it('should link to report abuse from user', () => {
      cy.visit('/article_editor_v1_user');

      // Make sure the dropdown has initialized
      cy.get('[data-dropdown-initialized]');

      cy.findByRole('button', { name: 'User actions' }).click();
      cy.findByRole('link', { name: 'Report Abuse' }).click();

      cy.url().should('contain', 'report-abuse');
      cy.url().should('contain', 'article_editor_v1_user');
    });
  });
});
