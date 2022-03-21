import { verifyAndDismissUserUpdatedMessage } from './userAdminUtilitites';

describe('Manage Tags Moderated', () => {
  beforeEach(() => {
    cy.testSetup();
    cy.fixture('users/adminUser.json').as('user');
    cy.get('@user').then((user) => {
      cy.loginUser(user);
    });
  });

  describe('When a tag to moderate is added to the list of moderated tags for a user', () => {
    it('should persist the added tags', () => {
      cy.visit('/admin/users/2');
      cy.findByRole('form', { name: 'Tag moderation' }).within(() => {
        cy.findByRole('textbox', { name: 'Assign tags' })
          .click()
          .type('tag1,tag2,')
          .blur();

        cy.findByRole('button', { name: 'Edit tag1' });
        cy.findByRole('button', { name: 'Edit tag1' });
        cy.findByRole('button', { name: 'Submit' }).click();
      });

      verifyAndDismissUserUpdatedMessage(
        'Tags moderated by the user have been updated',
      );
    });
  });
});
