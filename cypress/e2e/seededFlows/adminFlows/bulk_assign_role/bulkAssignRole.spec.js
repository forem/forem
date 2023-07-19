import {
  verifyAndDismissUserUpdatedMessage,
  verifyAndDismissDangerMessage,
} from '../users/userAdminUtilitites';
describe('Bulk Assign Role', () => {
  beforeEach(() => {
    cy.testSetup();
    cy.fixture('users/adminUser.json').as('user');

    cy.get('@user').then((user) => {
      cy.loginAndVisit(user, '/admin/member_manager/bulk_assign_role');
    });
  });

  it('should show success message for correct fields ', () => {
    cy.get('.crayons-select').select('Trusted');

    cy.get('.crayons-textfield[name="usernames"]').type('test1, test2, test3');

    cy.get('.crayons-textfield[name="note_for_current_role"]').type(
      'Sample note',
    );

    cy.findByText('Assign role').click();

    verifyAndDismissUserUpdatedMessage(
      'Roles are being added. The task will finish shortly.',
    );
  });

  it('should show error message if role is not selected ', () => {
    cy.get('.crayons-textfield[name="usernames"]').type('test1, test2, test3');

    cy.get('.crayons-textfield[name="note_for_current_role"]').type(
      'Sample note',
    );

    cy.findByText('Assign role').click();

    verifyAndDismissDangerMessage('Please choose a role to add.');
  });
});
