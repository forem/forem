describe('Posts Dashboard', () => {
  beforeEach(() => {
    cy.testSetup();
    cy.fixture('users/articleEditorV1User.json').as('user');

    cy.get('@user').then((user) => {
      cy.loginUser(user).then(() => {
        cy.createArticle({
          title: 'Test Article',
          tags: ['beginner', 'ruby', 'go'],
          content: `This is a test article's contents.`,
          published: true,
        }).then(() => {
          cy.visit('/dashboard');
        });
      });
    });
  });

  it('shows a toggleable dropdown for each post', () => {
    cy.findByRole('button', {
      name: 'More options for post: Test Article',
    }).as('dropdownButton');

    // Make sure the button is ready
    cy.get('button[id^=ellipsis-menu-trigger-][data-initialized]');

    cy.get('@dropdownButton').click();
    cy.findByRole('link', { name: 'Stats' }).should('have.focus');
    cy.findByRole('button', { name: 'Archive post' });

    // Check the dropdown closes again on click
    cy.get('@dropdownButton').click();
    cy.findByRole('link', { name: 'Stats' }).should('not.exist');

    // Re-open the dropdown and check it closes on Escape press
    cy.get('@dropdownButton').click();
    cy.get('body').type('{esc}');
    cy.get('@dropdownButton').should('have.focus');
    cy.findByRole('link', { name: 'Stats' }).should('not.exist');
  });

  it('links to stats for a post', () => {
    // Make sure the button is ready
    cy.get('button[id^=ellipsis-menu-trigger-][data-initialized]');

    cy.findByRole('button', {
      name: 'More options for post: Test Article',
    }).click();
    cy.findByRole('link', { name: 'Stats' }).click();
    cy.findByRole('heading', { name: 'Stats for "Test Article"' });

    // Go back to the dashboard, otherwise it's possible for Cypress to detect an error as the next beforeEach hook runs
    // (due to the logged out user not being able to view the stats page)
    cy.visit('/dashboard');
  });

  it('archives and unarchives a post', () => {
    // Verify Test Article is visible on the main page
    cy.findByRole('link', { name: 'Test Article' });

    // Make sure the button is ready
    cy.get('button[id^=ellipsis-menu-trigger-][data-initialized]');
    cy.findByRole('button', {
      name: 'More options for post: Test Article',
    }).click();
    cy.findByRole('button', { name: 'Archive post' }).click();

    // Check that the post has disappeared along with the dropdown
    cy.findByRole('button', { name: 'Archive post' }).should('not.exist');
    cy.findByRole('link', { name: 'Test Article' }).should('not.exist');

    // Currently, the 'Show archived' button is only visible after a page reload from the first post being archived
    cy.reload();
    cy.findByRole('link', { name: 'Show archived' }).click();

    // Check the post is in the archive
    cy.findByRole('link', { name: 'Test Article' });

    // Make sure the button is ready
    cy.get('button[id^=ellipsis-menu-trigger-][data-initialized]');
    cy.findByRole('button', {
      name: 'More options for post: Test Article',
    }).click();
    cy.findByRole('button', { name: 'Unarchive post' }).click();

    // The text should appear when the post is restored
    cy.findByText('Notifications Restored').should('exist');

    cy.reload();
    // Check that we no longer have an archive, and the post shows as normal
    cy.findByRole('link', { name: 'Show archived' }).should('not.exist');
    cy.findByRole('link', { name: 'Test Article' });
  });
});
