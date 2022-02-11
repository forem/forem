// More on roles, https://admin.forem.com/docs/forem-basics/user-roles
function openOrgModal(ctaText = 'Add organization') {
  cy.getModal().should('not.exist');
  cy.findByRole('button', { name: ctaText }).click();

  return cy.getModal();
}

function closeUserUpdatedMessage(message) {
  cy.findByText(message).should('exist');
  cy.findByRole('button', { name: 'Close' }).click();
  cy.findByText(message).should('not.exist');
}

describe('Manage User Organziations', () => {
  describe('As an admin', () => {
    beforeEach(() => {
      cy.testSetup();
      cy.fixture('users/adminUser.json').as('user');
      cy.get('@user').then((user) => {
        cy.loginUser(user);
      });
    });

    it(`should add a user to an organization`, () => {
      cy.visit('/admin/users/3');

      cy.findByText('This user is not a part of any organization yet.').should(
        'be.visible',
      );

      openOrgModal().within(() => {
        cy.findByRole('spinbutton', { name: 'Organization ID' }).type(1);
        cy.findByRole('button', { name: 'Add organization' }).click();
      });

      closeUserUpdatedMessage('User was successfully added to Bachmanity');
      cy.getModal().should('not.exist');

      // Focusing on the link is required to make buttons visible.
      cy.findByRole('link', { name: 'Bachmanity' }).focus();
      cy.findByRole('button', {
        name: 'Edit Bachmanity organization membership',
      });

      cy.findByRole('button', {
        name: 'Revoke Bachmanity organization membership',
      });
    });

    it('should add a user to multiple organizations', () => {
      cy.visit('/admin/users/3');

      cy.findByText('This user is not a part of any organization yet.').should(
        'be.visible',
      );

      openOrgModal().within(() => {
        cy.findByRole('spinbutton', { name: 'Organization ID' }).type(1);
        cy.findByRole('button', { name: 'Add organization' }).click();
      });

      closeUserUpdatedMessage('User was successfully added to Bachmanity');

      openOrgModal('Add another organization').within(() => {
        cy.findByRole('spinbutton', { name: 'Organization ID' }).type(2);
        cy.findByRole('button', { name: 'Add organization' }).click();
      });

      closeUserUpdatedMessage('User was successfully added to Awesome Org');
      cy.getModal().should('not.exist');

      // Focusing on the link is required to make buttons visible.
      cy.findByRole('link', { name: 'Bachmanity' }).focus();
      cy.findByRole('button', {
        name: 'Edit Bachmanity organization membership',
      });

      cy.findByRole('button', {
        name: 'Revoke Bachmanity organization membership',
      });

      cy.findByRole('link', { name: 'Awesome Org' }).focus();
      cy.findByRole('button', {
        name: 'Edit Awesome Org organization membership',
      });

      cy.findByRole('button', {
        name: 'Revoke Awesome Org organization membership',
      });
    });

    it(`should edit a user's membership to an organization`, () => {
      cy.visit('/admin/users/2');

      cy.findByRole('link', { name: 'Awesome Org' }).focus();
      cy.findByRole('button', {
        name: 'Edit Awesome Org organization membership',
      }).click();

      cy.getModal().within(() => {
        cy.findByRole('combobox', { name: 'Permission level' }).select('admin');
        cy.findByRole('button', { name: 'Update' }).click();
      });

      closeUserUpdatedMessage('User was successfully updated to admin');
      cy.getModal().should('not.exist');
    });

    it(`should add a user to another organization`, () => {
      cy.visit('/admin/users/2');

      openOrgModal('Add another organization').within(() => {
        cy.findByRole('spinbutton', { name: 'Organization ID' }).type(1);
        cy.findByRole('button', { name: 'Add organization' }).click();
      });

      closeUserUpdatedMessage('User was successfully added to Bachmanity');
      cy.getModal().should('not.exist');

      cy.findByRole('link', { name: 'Awesome Org' });
      cy.findByRole('link', { name: 'Bachmanity' });
    });

    it(`should revoke a user's membership to an organization`, () => {
      cy.visit('/admin/users/2');

      cy.findByRole('link', { name: 'Awesome Org' }).focus();
      cy.findByRole('button', {
        name: 'Revoke Awesome Org organization membership',
      }).click();

      closeUserUpdatedMessage('User was successfully removed from Awesome Org');
    });
  });
});
