import { verifyAndDismissFlashMessage } from '../shared/utilities';

function openUserOptions(callback) {
  cy.findByRole('button', { name: 'Options' })
    .should('have.attr', 'aria-haspopup', 'true')
    .should('have.attr', 'aria-expanded', 'false')
    .click()
    .then(([button]) => {
      expect(button.getAttribute('aria-expanded')).to.equal('true');
      const dropdownId = button.getAttribute('aria-controls');

      cy.get(`#${dropdownId}`).within(callback);
    });
}

describe('Manage User Options', () => {
  describe('As an admin', () => {
    beforeEach(() => {
      cy.testSetup();
      cy.fixture('users/adminUser.json').as('user');
      cy.get('@user').then((user) => {
        cy.loginAndVisit(user, '/admin/member_manager/users/2');
      });
    });

    it(`should export a user's data to an admin`, () => {
      openUserOptions(() => {
        cy.findByRole('button', { name: 'Export data' }).click();
      });

      cy.getModal().within(() => {
        cy.findByRole('button', { name: 'Export to Admin' }).click();
      });

      verifyAndDismissFlashMessage(
        'Data exported to the admin. The job will complete momentarily.',
        'flash-success',
      );
    });

    it(`should export a user's data to the user`, () => {
      openUserOptions(() => {
        cy.findByRole('button', { name: 'Export data' }).click();
      });

      cy.getModal().within(() => {
        cy.findByRole('button', { name: 'Export to User' }).click();
      });

      verifyAndDismissFlashMessage(
        'Data exported to the user. The job will complete momentarily.',
        'flash-success',
      );
    });

    it(`should merge a user's account with another account`, () => {
      openUserOptions(() => {
        cy.findByRole('button', { name: 'Merge users' }).click();
      });

      cy.getModal().within(() => {
        cy.findByRole('spinbutton', { name: 'User ID' }).type('3');
        cy.findByRole('button', { name: 'Merge and delete' }).click();
      });
    });

    it(`should banish a user for spam`, () => {
      openUserOptions(() => {
        cy.findByRole('button', { name: 'Banish user' }).click();
      });

      cy.getModal().within(() => {
        cy.findByRole('button', { name: 'Banish Trusted User 1 \\:/' }).click();
      });

      verifyAndDismissFlashMessage(
        'This user is being banished in the background. The job will complete soon.',
        'flash-success',
      );
    });

    it(`should delete a user`, () => {
      openUserOptions(() => {
        cy.findByRole('button', { name: 'Delete user' }).click();
      });

      cy.getModal().within(() => {
        cy.findByRole('button', {
          name: 'Delete now',
        }).click();
      });

      verifyAndDismissFlashMessage(
        '@trusted_user_1 (email: trusted-user-1@forem.local, user_id: 2) has been fully deleted. If this is a GDPR delete, delete them from Mailchimp & Google Analytics and confirm on the page.',
        'flash-success',
      );
    });

    it(`should not unpublish all posts of a user if the user has no posts`, () => {
      openUserOptions(() => {
        cy.findByRole('button', { name: 'Unpublish all posts' }).should(
          'not.exist',
        );
      });
    });

    it(`should not remove social accounts of a user if the user has no social accounts`, () => {
      openUserOptions(() => {
        cy.findByRole('button', { name: 'Remove social accounts' }).should(
          'not.exist',
        );
      });
    });
  });
});
