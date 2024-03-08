import { verifyAndDismissFlashMessage } from '../shared/utilities';

function openOrganizationOptions(callback) {
  cy.findByRole('button', { name: 'Options' }).as('options');
  cy.get('@options').should('have.attr', 'aria-haspopup', 'true');
  cy.get('@options').should('have.attr', 'aria-expanded', 'false');
  // Can't find a better way to get to the aria-controls attribute at the moment
  // Might be possible if we use pipe(click) with the helper method used in AdjustPostTags spec,
  // instead of the .then syntax... but skipping the linter may be safest of all.
  /* eslint-disable-next-line cypress/unsafe-to-chain-command */
  cy.get('@options')
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
