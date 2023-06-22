import { verifyAndDismissUserUpdatedMessage } from './userAdminUtilitites';

// More on roles, https://admin.forem.com/docs/forem-basics/user-roles
function openRolesModal() {
  cy.getModal().should('not.exist');
  cy.findByRole('button', { name: 'Assign role' }).click();

  return cy.getModal();
}

function checkUserStatus(status) {
  cy.findByTestId('user-status').should('have.text', status);
}

describe('Manage User Roles', () => {
  describe('As an admin', () => {
    beforeEach(() => {
      cy.testSetup();
      cy.fixture('users/adminUser.json').as('user');
      cy.get('@user').then((user) => {
        cy.loginUser(user);
      });
    });

    describe('Changing Roles', () => {
      beforeEach(() => {
        cy.visit('/admin/member_manager/users/2');
      });

      it('Remove other roles and add a note when Warned role added', () => {
        checkUserStatus('Trusted');

        cy.findByRole('button', { name: 'Remove role: Trusted' }).should(
          'exist',
        );
        openRolesModal().within(() => {
          cy.findByRole('combobox', { name: 'Role' }).select('Warned');
          cy.findByRole('textbox', { name: 'Add a note to this action:' }).type(
            'some reason',
          );
          cy.findByRole('button', { name: 'Add' }).click();
        });

        cy.getModal().should('not.exist');
        verifyAndDismissUserUpdatedMessage();

        cy.findByRole('button', { name: 'Remove role: Warned' }).should(
          'exist',
        );
        checkUserStatus('Warned');
        cy.findByRole('button', { name: 'Remove role: Trusted' }).should(
          'not.exist',
        );

        cy.findByRole('navigation', { name: 'Member details' })
          .findByRole('link', { name: 'Notes' })
          .click();

        cy.findByText('some reason').should('exist');
        cy.findByText(/Warned by/).should('exist');
      });

      it('should remove other roles & add a note when Suspend role added', () => {
        cy.findByRole('button', { name: 'Remove role: Trusted' });
        openRolesModal().within(() => {
          cy.findByRole('combobox', { name: 'Role' }).select('Suspended');
          cy.findByRole('textbox', { name: 'Add a note to this action:' }).type(
            'some reason',
          );
          cy.findByRole('button', { name: 'Add' }).click();
        });

        cy.getModal().should('not.exist');
        verifyAndDismissUserUpdatedMessage();

        cy.findByRole('button', {
          name: "Suspended You can't remove this role.",
        }).should('exist');
        checkUserStatus('Suspended');

        cy.findByRole('button', { name: 'Remove role: Trusted' }).should(
          'not.exist',
        );

        cy.findByRole('navigation', { name: 'Member details' })
          .findByRole('link', { name: 'Notes' })
          .click();
        cy.findByText('some reason').should('exist');
        cy.findByText(/Suspended by/).should('exist');
      });

      it('should remove a role', () => {
        checkUserStatus('Trusted');
        cy.findByRole('button', { name: 'Remove role: Trusted' }).click();
        cy.findByRole('button', { name: 'Remove role: Trusted' }).should(
          'not.exist',
        );
        checkUserStatus('Good standing');
      });
    });

    describe('Adding Roles', () => {
      beforeEach(() => {
        cy.visit('/admin/member_manager/users/3');
      });

      it('should not add a role if a reason is missing.', () => {
        checkUserStatus('Good standing');
        cy.findByText('No roles assigned yet.').should('be.visible');

        openRolesModal().within(() => {
          cy.findByRole('combobox', { name: 'Role' }).select('Warned');
          cy.findByRole('button', { name: 'Add' }).click();
          cy.findByRole('button', { name: 'Close' }).click();
        });

        checkUserStatus('Good standing');
        cy.findByRole('button', { name: 'Remove role: Warned' }).should(
          'not.exist',
        );
      });

      it('should add multiple roles', () => {
        cy.findByText('No roles assigned yet.').should('be.visible');

        openRolesModal().within(() => {
          cy.findByRole('combobox', { name: 'Role' }).select('Warned');
          cy.findByRole('textbox', { name: 'Add a note to this action:' }).type(
            'some reason',
          );
          cy.findByRole('button', { name: 'Add' }).click();
        });

        cy.getModal().should('not.exist');
        verifyAndDismissUserUpdatedMessage();
        checkUserStatus('Warned');

        cy.findByRole('button', { name: 'Remove role: Warned' }).should(
          'exist',
        );

        openRolesModal().within(() => {
          cy.findByRole('combobox', { name: 'Role' }).select(
            'Comment Suspended',
          );
          cy.findByRole('textbox', { name: 'Add a note to this action:' }).type(
            'some reason',
          );
          cy.findByRole('button', { name: 'Add' }).click();
        });

        cy.getModal().should('not.exist');
        verifyAndDismissUserUpdatedMessage();
        checkUserStatus('Warned');

        cy.findByRole('button', { name: 'Remove role: Warned' }).should(
          'exist',
        );
        cy.findByRole('button', {
          name: 'Remove role: Comment Suspended',
        }).should('exist');
      });
    });
  });
});
