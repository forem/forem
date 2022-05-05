describe('Invited users', () => {
  beforeEach(() => {
    cy.testSetup();
    cy.fixture('users/adminUser.json').as('user');
    cy.get('@user').then((user) => {
      cy.loginUser(user)
        .then(() =>
          cy.inviteUser({
            name: 'Test user',
            email: 'test@test.com',
          }),
        )
        .then(() =>
          cy.visitAndWaitForUserSideEffects(
            '/admin/member_manager/invitations',
          ),
        );
    });
  });

  // Helper function for cypress-pipe
  const click = (el) => el.click();

  describe('small screens', () => {
    beforeEach(() => {
      cy.viewport('iphone-x');
    });

    it('searches for invited user', () => {
      // The single invited user should be visible on the page
      cy.findByRole('article').findByText('test@test.com').should('exist');

      cy.findByRole('button', { name: 'Expand search' })
        .should('have.attr', 'aria-expanded', 'false')
        .pipe(click)
        .should('have.attr', 'aria-expanded', 'true');

      // Search for a term that should match the entry
      searchForMember('test');

      cy.url().should('contain', 'search=test');
      cy.findByRole('article').findByText('test@test.com').should('exist');

      // Search for a term that shouldn't match the entry
      cy.findByRole('button', { name: 'Expand search' })
        .should('have.attr', 'aria-expanded', 'false')
        .pipe(click)
        .should('have.attr', 'aria-expanded', 'true');

      searchForMember('something');
      cy.url().should('contain', 'search=something');
      // No entries should exist
      cy.findByRole('article').should('not.exist');
    });

    it('resends an invite', () => {
      cy.findByRole('article').findByText('test@test.com').should('exist');
      resendInviteForTestMember();
      cy.findByText('Invite resent to test@test.com.').should('exist');
    });

    it('cancels an invite', () => {
      cy.findByRole('article').findByText('test@test.com').should('exist');
      cancelInviteForTestMember();

      cy.findByText('Invite cancelled for test@test.com.').should('exist');

      // No entries should exist
      cy.findByRole('article').should('not.exist');
    });
  });

  describe('large screens', () => {
    beforeEach(() => {
      cy.viewport('macbook-16');
    });

    it('searches for an invited user', () => {
      // The single invited user should be visible on the page
      cy.findByRole('table').findByText('test@test.com').should('exist');

      // Search for a term that should match the entry
      searchForMember('test');

      cy.url().should('contain', 'search=test');
      cy.findByRole('table').findByText('test@test.com').should('exist');

      // Search for a term that shouldn't match the entry
      searchForMember('something');
      cy.url().should('contain', 'search=something');
      cy.findByRole('table').findByText('test@test.com').should('not.exist');
    });

    it('resends an invite', () => {
      cy.findByRole('table').findByText('test@test.com').should('exist');

      resendInviteForTestMember();

      cy.findByText('Invite resent to test@test.com.').should('exist');
    });

    it('cancels an invite', () => {
      cy.findByRole('table').findByText('test@test.com').should('exist');
      cancelInviteForTestMember();

      cy.findByText('Invite cancelled for test@test.com.').should('exist');

      // Table entry should now be gone
      cy.findByRole('table').findByText('test@test.com').should('not.exist');
    });
  });

  const searchForMember = (searchTerm) => {
    cy.findByRole('textbox', {
      name: 'Search invited members by name, email, or username',
    })
      .clear()
      .type(searchTerm);
    cy.findByRole('button', { name: 'Search' }).click();
  };

  const resendInviteForTestMember = () => {
    cy.findByRole('button', { name: 'Invitation actions: test@test.com' })
      .pipe(click)
      .should('have.attr', 'aria-expanded', 'true');

    cy.findByRole('button', { name: 'Resend invite' }).click();
  };

  const cancelInviteForTestMember = () => {
    cy.findByRole('button', { name: 'Invitation actions: test@test.com' })
      .pipe(click)
      .should('have.attr', 'aria-expanded', 'true');

    cy.findByRole('button', { name: 'Cancel invite' }).click();
  };
});

describe('No invited members', () => {
  beforeEach(() => {
    cy.testSetup();
    cy.fixture('users/adminUser.json').as('user');
    cy.get('@user').then((user) => {
      cy.loginAndVisit(user, '/admin/member_manager/invitations');
    });
  });

  it('displays an empty state', () => {
    cy.findByText('No members invited yet.').should('exist');
  });
});
