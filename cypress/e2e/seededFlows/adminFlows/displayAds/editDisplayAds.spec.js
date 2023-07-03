describe('Display Ads Form', () => {
  context('when creating a new display ad', () => {
    beforeEach(() => {
      cy.testSetup();
      cy.fixture('users/adminUser.json').as('user');

      cy.get('@user').then((user) => {
        cy.loginAndVisit(user, '/admin/customization/display_ads');
        cy.findByRole('link', { name: 'Make A New Display Ad' }).click({
          force: true,
        });
      });
    });

    it('should not show the tags field if the placement is not one of the post page areas', () => {
      cy.findByRole('combobox', { name: 'Placement Area:' }).select(
        'Sidebar Right (Home)',
      );
      cy.findByRole('input', { name: 'Targeted Tag(s)' }).should('not.exist');
    });

    it('should show the tags field if the placement is "Below the comment section"', () => {
      cy.findByRole('combobox', { name: 'Placement Area:' }).select(
        'Below the comment section',
      );
      cy.findByLabelText('Targeted Tag(s)').should('exist');
    });

    it('should show the tags field if the placement is "Sidebar Right (Individual Post)"', () => {
      cy.findByRole('combobox', { name: 'Placement Area:' }).select(
        'Sidebar Right (Individual Post)',
      );
      cy.findByLabelText('Targeted Tag(s)').should('exist');
    });

    it('should not show the audience segment field if the display to is logged-out users', () => {
      cy.findByRole('radio', { name: 'Only logged out users' }).click();
      cy.findByLabelText('Users who:').should('not.be.visible');
    });

    it('should not show the audience segment field if the display to is all users', () => {
      cy.findByRole('radio', { name: 'All users' }).click();
      cy.findByLabelText('Users who:').should('not.be.visible');
    });

    it('should show the audience segment field if the display to is logged-in users', () => {
      cy.findByRole('radio', { name: 'Only logged in users' }).click();
      cy.findByLabelText('Users who:').should('be.visible');
    });

    it('should not include manual segments in the audience segment field', () => {
      cy.findByRole('radio', { name: 'Only logged in users' }).click();
      cy.findByLabelText('Users who:')
        .as('audienceSegments')
        .should('be.visible');

      cy.get('@audienceSegments').select('Are trusted').should('exist');
      cy.get('@audienceSegments').select('Have not posted yet').should('exist');
      cy.get('@audienceSegments')
        .select('Have not set an experience level')
        .should('exist');

      cy.get('@audienceSegments')
        .contains('Managed elsewhere')
        .should('not.exist');
    });
  });

  context('when editing a display ad with a manually managed audience', () => {
    beforeEach(() => {
      cy.testSetup();
      cy.fixture('users/adminUser.json').as('user');

      cy.get('@user').then((user) => {
        cy.loginAndVisit(user, '/admin/customization/display_ads');
        cy.findByRole('link', { name: 'Manual Audience Billboard' }).click({
          force: true,
        });
      });
    });

    it('shows the audience segment field but disabled', () => {
      cy.findByLabelText('Users who:')
        .as('audienceSegments')
        .should('be.disabled');

      cy.get('@audienceSegments')
        .find(':selected')
        .should('have.text', 'Managed elsewhere');

      cy.get('@audienceSegments').contains('Are trusted').should('not.exist');
      cy.get('@audienceSegments')
        .contains('Have not posted yet')
        .should('not.exist');
      cy.get('@audienceSegments')
        .contains('Have not set an experience level')
        .should('not.exist');
    });
  });
});
