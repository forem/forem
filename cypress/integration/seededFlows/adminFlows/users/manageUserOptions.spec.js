function openUserOptions() {
  cy.findByRole('button', { name: 'Options' }).click();
}

function closeUserUpdatedMessage(message) {
  cy.findByTestId('flash-success')
    .as('success')
    .then((element) => {
      expect(element.text().trim()).equal(message);
    });

  cy.get('@success').within(() => {
    cy.findByRole('button', { name: 'Close' }).click();
  });

  cy.findByTestId('flash-success').should('not.exist');
}

describe('Manage User Options', () => {
  describe('As an admin', () => {
    beforeEach(() => {
      cy.testSetup();
      cy.fixture('users/adminUser.json').as('user');
      cy.get('@user').then((user) => {
        cy.loginAndVisit(user, '/admin/users/2');
        openUserOptions();
      });
    });

    it(`should verify a user's email address`, () => {
      cy.findByRole('button', { name: 'Verify email address' }).click();

      closeUserUpdatedMessage('Verification email sent!');
    });

    it(`should export a user's data to an admin`, () => {
      cy.findByRole('button', { name: 'Export data' }).click();

      cy.getModal().within(() => {
        cy.findByRole('button', { name: 'Export to Admin' }).click();
      });

      closeUserUpdatedMessage(
        'Data exported to the admin. The job will complete momentarily.',
      );
    });

    it(`should export a user's data to the user`, () => {
      cy.findByRole('button', { name: 'Export data' }).click();

      cy.getModal().within(() => {
        cy.findByRole('button', { name: 'Export to User' }).click();
      });

      closeUserUpdatedMessage(
        'Data exported to the user. The job will complete momentarily.',
      );
    });

    it(`should merge a user's account with another account`, () => {
      cy.findByRole('button', { name: 'Merge accounts' }).click();

      cy.getModal().within(() => {
        cy.findByRole('spinbutton', { name: 'User ID' }).type('3');
        cy.findByRole('button', { name: 'Merge users' }).click();
      });
    });

    it(`should banish a user for spam`, () => {
      cy.findByRole('button', { name: 'Banish for spam' }).click();

      cy.getModal().within(() => {
        cy.findByRole('button', { name: 'Banish User for spam' }).click();
      });

      closeUserUpdatedMessage(
        'This user is being banished in the background. The job will complete soon.',
      );
    });

    it(`should delete a user`, () => {
      cy.findByRole('button', { name: 'Delete user' }).click();

      cy.getModal().within(() => {
        cy.findByRole('button', {
          name: 'Fully Delete User & All Activity',
        }).click();
      });

      closeUserUpdatedMessage(
        '@trusted_user_1 (email: trusted-user-1@forem.local, user_id: 2) has been fully deleted. If this is a GDPR delete, delete them from Mailchimp & Google Analytics  and confirm on the page.',
      );
    });
  });
});
