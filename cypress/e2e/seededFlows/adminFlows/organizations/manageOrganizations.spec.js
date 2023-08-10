import { verifyAndDismissFlashMessage } from '../shared/utilities';

function openOrganizationOptions(callback) {
  cy.findByRole('button', { name: 'Options' }).should(
    'have.attr',
    'aria-haspopup',
    'true',
  );
  cy.findByRole('button', { name: 'Options' }).should(
    'have.attr',
    'aria-expanded',
    'false',
  );
  cy.findByRole('button', { name: 'Options' }).click();
  expect(
    cy.findByRole('button', { name: 'Options' }).getAttribute('aria-expanded'),
  ).to.equal('true');
  cy.findByRole('button', { name: 'Options' })
    .getAttribute('aria-controls')
    .within(callback);
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
        cy.findAllByRole('link', { name: '@Awesome Org' }).first().click();
      });
    });

    it('should show a notice about the scheduled job', () => {
      openOrganizationOptions(() => {
        cy.findByRole('button', { name: 'Delete organization' }).click();
      });

      cy.getModal().within(() => {
        cy.findByRole('button', { name: 'Delete organizion now' }).click();
      });

      verifyAndDismissFlashMessage(
        `Organization, "Awesome Org", deletion is scheduled.`,
        'flash-settings_notice',
      );
    });
  });

  describe('As an organization that has existing credits', () => {
    beforeEach(() => {
      cy.testSetup();
      cy.fixture('users/adminUser.json').as('user');
      cy.get('@user').then((user) => {
        cy.loginAndVisit(user, '/admin/content_manager/organizations');
      });

      cy.findByRole('table').within(() => {
        cy.findAllByRole('link', { name: '@Credits Org' }).first().click();
      });
    });

    it('should show an error', () => {
      openOrganizationOptions(() => {
        cy.findByRole('button', { name: 'Delete organization' }).click();
      });

      cy.getModal().within(() => {
        cy.findByText(
          'You cannot delete an organization that has associated credits.',
        ).should('exist');
      });
    });
  });
});
