describe('Chat message options', () => {
  beforeEach(() => {
    cy.testSetup();

    cy.intercept(
      { method: 'POST', url: '/chat_channels/**/open' },
      { body: {} },
    );

    cy.fixture('users/chatUser2.json').as('user');
    cy.get('@user').then((user) => {
      cy.loginAndVisit(user, '/connect/test-chat-channel');
    });
  });

  it("should show report options for another user's messages", () => {
    // Enter the test chat
    cy.findByRole('button', { name: 'Toggle request manager' }).click();
    cy.findByRole('button', { name: 'Accept' }).click();
    cy.findByRole('button', { name: 'Accept' }).should('not.exist');

    // Check the report menu is present and opens
    cy.findByRole('button', { name: 'Report message options' }).as(
      'reportMenuButton',
    );
    cy.get('@reportMenuButton').click();
    cy.findByRole('button', { name: 'Report Abuse' }).should('have.focus');

    // Check Escape closes the menu
    cy.get('body').type('{esc}');
    cy.get('@reportMenuButton').should('have.focus');
    cy.findByRole('button', { name: 'Report Abuse' }).should('not.exist');
  });

  it("should show options for a user's own messages", () => {
    // Enter the test chat
    cy.findByRole('button', { name: 'Toggle request manager' }).click();
    cy.findByRole('button', { name: 'Accept' }).click();
    // Wait for acceptance to happen
    cy.findByRole('button', { name: 'Accept' }).should('not.exist');

    // Send a message
    cy.findByRole('textbox', { name: 'Compose a message' })
      .click()
      .focus()
      .type('message');
    cy.findByRole('button', { name: 'Send' }).click();
    // Wait for the message to send
    cy.findByRole('textbox', { name: 'Compose a message' }).should(
      'have.value',
      '',
    );

    // The sent message doesn't show up without reload
    cy.reload();

    // Check the menu opens and focuses the first item
    cy.findByRole('button', { name: 'Message options menu' }).as(
      'optionsMenuButton',
    );
    cy.get('@optionsMenuButton').click();
    cy.findByRole('button', { name: 'Edit' }).should('have.focus');
    cy.findByRole('button', { name: 'Delete' }).should('exist');

    // Simulate an escape keypress anywhere on the page
    cy.get('body').type('{esc}');
    cy.get('@optionsMenuButton').should('have.focus');
    cy.findByRole('button', { name: 'Edit' }).should('not.exist');
    cy.findByRole('button', { name: 'Delete' }).should('not.exist');
  });
});
