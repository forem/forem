import { verifyAndDismissUserUpdatedMessage } from './userAdminUtilitites';

describe('Manage Tags Moderated', () => {
  beforeEach(() => {
    cy.testSetup();
    cy.fixture('users/adminUser.json').as('user');
    cy.get('@user').then((user) => {
      cy.loginUser(user);
    });
  });

  describe('When moderating tags for a user', () => {
    it('should add tags', () => {
      cy.visit('/admin/users/2');
      cy.findByRole('form', { name: 'Tag moderation' }).within(() => {
        cy.findByRole('textbox', { name: 'Assign tags' })
          .click()
          .type('tag1,tag2,')
          .blur();

        cy.findByRole('button', { name: 'Edit tag1' });
        cy.findByRole('button', { name: 'Edit tag2' });
        cy.findByRole('button', { name: 'Submit' }).click();
      });

      verifyAndDismissUserUpdatedMessage(
        'Tags moderated by the user have been updated',
      );
    });

    it('should remove tags', () => {
      cy.visit('/admin/users/1');
      cy.findByRole('form', { name: 'Tag moderation' }).within(() => {
        cy.findByRole('button', { name: 'Remove tag1' }).click();
        cy.findByRole('button', { name: 'Submit' }).click();
      });

      verifyAndDismissUserUpdatedMessage(
        'Tags moderated by the user have been updated',
      );

      cy.findByRole('button', { name: 'Edit tag1' }).should('not.exist');
      cy.findByRole('button', { name: 'Edit tag2' }).should('exist');
    });
  });
});
