import { verifyAndDismissFlashMessage } from '../shared/adminUtilities';

function openOrganizationOptions(callback) {
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

describe('Manage Organization Options', () => {
  describe('As a super admin', () => {
    beforeEach(() => {
      cy.testSetup();
      cy.fixture('users/adminUser.json').as('user');
      cy.get('@user').then((user) => {
        cy.loginAndVisit(user, '/admin/content_manager/organizations');
      });

      cy.findByRole('table').within(() => {
        cy.findAllByRole('link').first().click();
      });
    });

    it('should show an error', () => {
      openOrganizationOptions(() => {
        cy.findByRole('button', { name: 'Delete organization' }).click();
      });

      cy.getModal().within(() => {
        cy.findByRole('button', { name: 'Delete organizion now' }).click();
      });

      verifyAndDismissFlashMessage(`Your organization deletion is scheduled.`);
    });
  });
});
