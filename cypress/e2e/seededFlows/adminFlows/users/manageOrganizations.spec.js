import { verifyAndDismissFlashMessage } from '../shared/utilities';

// More on roles, https://admin.forem.com/docs/forem-basics/user-roles
function openOrgModal(ctaText = 'Add organization') {
  cy.getModal().should('not.exist');
  cy.findByRole('button', { name: ctaText }).click();

  return cy.getModal();
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
      cy.visit('/admin/member_manager/users/3');

      cy.findByText('Not part of any organization yet.').should('be.visible');

      openOrgModal().within(() => {
        cy.findByRole('spinbutton', { name: 'Organization ID' }).type(1);
        cy.findByRole('button', { name: 'Add organization' }).click();
      });

      verifyAndDismissFlashMessage(
        'User was successfully added to Bachmanity',
        'flash-success',
      );
      cy.getModal().should('not.exist');

      // Focusing on the link is required to make buttons visible.
      cy.findAllByRole('link', { name: 'Bachmanity' }).first().focus();
      cy.findByRole('button', {
        name: 'Edit Bachmanity organization membership',
      });

      cy.findByRole('button', {
        name: 'Revoke Bachmanity organization membership',
      });
    });

    it('should add a user to multiple organizations', () => {
      cy.visit('/admin/member_manager/users/3');

      cy.findByText('Not part of any organization yet.').should('be.visible');

      openOrgModal().within(() => {
        cy.findByRole('spinbutton', { name: 'Organization ID' }).type(1);
        cy.findByRole('button', { name: 'Add organization' }).click();
      });

      verifyAndDismissFlashMessage(
        'User was successfully added to Bachmanity',
        'flash-success',
      );

      openOrgModal('Add organization').within(() => {
        cy.findByRole('spinbutton', { name: 'Organization ID' }).type(2);
        cy.findByRole('button', { name: 'Add organization' }).click();
      });

      verifyAndDismissFlashMessage(
        'User was successfully added to Awesome Org',
        'flash-success',
      );
      cy.getModal().should('not.exist');

      // Focusing on the link is required to make buttons visible.
      cy.findAllByRole('link', { name: 'Bachmanity' }).first().focus();
      cy.findByRole('button', {
        name: 'Edit Bachmanity organization membership',
      });

      cy.findByRole('button', {
        name: 'Revoke Bachmanity organization membership',
      });

      cy.findAllByRole('link', { name: 'Awesome Org' }).first().focus();
      cy.findByRole('button', {
        name: 'Edit Awesome Org organization membership',
      });

      cy.findByRole('button', {
        name: 'Revoke Awesome Org organization membership',
      });
    });

    it(`should edit a user's membership to an organization`, () => {
      cy.visit('/admin/member_manager/users/2');

      cy.findAllByRole('link', { name: 'Awesome Org' }).first().focus();
      cy.findByRole('button', {
        name: 'Edit Awesome Org organization membership',
      }).click();

      cy.getModal().within(() => {
        cy.findByRole('combobox', { name: 'Role' }).select('admin');
        cy.findByRole('button', { name: 'Submit' }).click();
      });

      verifyAndDismissFlashMessage(
        'User was successfully updated to admin',
        'flash-success',
      );
      cy.getModal().should('not.exist');
    });

    it(`should add a user to another organization`, () => {
      cy.visit('/admin/member_manager/users/2');

      openOrgModal('Add organization').within(() => {
        cy.findByRole('spinbutton', { name: 'Organization ID' }).type(1);
        cy.findByRole('button', { name: 'Add organization' }).click();
      });

      verifyAndDismissFlashMessage(
        'User was successfully added to Bachmanity',
        'flash-success',
      );
      cy.getModal().should('not.exist');

      // Two links currently exist for every org (image and name)
      cy.findAllByRole('link', { name: 'Awesome Org' }).should(
        'have.length',
        2,
      );
      cy.findAllByRole('link', { name: 'Bachmanity' }).should('have.length', 2);
    });

    it(`should revoke a user's membership to an organization`, () => {
      cy.visit('/admin/member_manager/users/2');

      cy.findAllByRole('link', { name: 'Awesome Org' }).first().focus();
      cy.findByRole('button', {
        name: 'Revoke Awesome Org organization membership',
      }).click();

      verifyAndDismissFlashMessage(
        'User was successfully removed from Awesome Org',
        'flash-success',
      );
    });
  });
});
