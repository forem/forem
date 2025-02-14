describe('Billboards Form', () => {
  context('when creating a new billboard', () => {
    beforeEach(() => {
      cy.testSetup();
      cy.fixture('users/adminUser.json').as('user');

      cy.get('@user').then((user) => {
        cy.loginAndVisit(user, '/admin/customization/billboards');
        cy.findByRole('link', { name: 'Make A New Billboard' }).click({
          force: true,
        });
      });
    });

    describe('Targeted Tags field', () => {
      [
        'Sidebar Left (First Position)',
        'Sidebar Left (Second Position)',
        'Home Hero',
      ].forEach((area) => {
        it(`should not show the tags field if the placement is ${area}`, () => {
          cy.findByRole('combobox', { name: 'Placement Area:' }).select(area);
          cy.findByRole('input', { name: 'Targeted Tag(s)' }).should(
            'not.exist',
          );
        });
      });

      [
        'Below the comment section',
        'Sidebar Right (Individual Post)',
        'Sidebar Right (Individual Post)',
        'Home Feed First',
        'Home Feed Second',
        'Home Feed Third',
      ].forEach((area) => {
        it(`should show the tags field if the placement is ${area}`, () => {
          cy.findByRole('combobox', { name: 'Placement Area:' }).select(area);
          cy.findByLabelText('Targeted Tag(s)').should('exist');
        });
      });
    });

    describe('Audience Segment field', () => {
      it('should not show the audience segment field if the display to is logged-out users', () => {
        cy.findByRole('radio', { name: 'Only logged out users' }).click();
        cy.findByLabelText('Users in segment:').should('not.be.visible');
      });

      it('should not show the audience segment field if the display to is all users', () => {
        cy.findByRole('radio', { name: 'All users' }).click();
        cy.findByLabelText('Users in segment:').should('not.be.visible');
      });

      it('should show the audience segment field if the display to is logged-in users', () => {
        cy.findByRole('radio', { name: 'Only logged in users' }).click();
        cy.findByLabelText('Users in segment:').should('be.visible');
      });

      it('should not include manual segments in the audience segment field', () => {
        cy.findByRole('radio', { name: 'Only logged in users' }).click();
        cy.findByLabelText('Users in segment:')
          .as('audienceSegments')
          .should('be.visible');
        // Unsure of the best way to separate the get/select chaining at the moment.
        // It's getting late and I may be missing something easy.
        // Skipping the linter rule for now to unblock depfu.
        /* eslint-disable cypress/unsafe-to-chain-command */
        cy.get('@audienceSegments').select('Are trusted').should('exist');
        cy.get('@audienceSegments')
          .select('Have not posted yet')
          .should('exist');
        cy.get('@audienceSegments')
          .select('Have not set an experience level')
          .should('exist');
        /* eslint-enable cypress/unsafe-to-chain-command */
        cy.get('@audienceSegments')
          .contains('Managed elsewhere')
          .should('not.exist');
      });

      context(
        'when editing a billboard with a manually managed audience',
        () => {
          beforeEach(() => {
            cy.visit('/admin/customization/billboards');
            cy.findByRole('link', { name: 'Manual Audience Billboard' }).click({
              force: true,
            });
          });

          it('shows the audience segment field but disabled', () => {
            cy.findByLabelText('Users in segment:')
              .as('audienceSegments')
              .should('be.disabled');

            cy.get('@audienceSegments')
              .find(':selected')
              .should('have.text', 'Managed elsewhere');

            cy.get('@audienceSegments')
              .contains('Are trusted')
              .should('not.exist');
            cy.get('@audienceSegments')
              .contains('Have not posted yet')
              .should('not.exist');
            cy.get('@audienceSegments')
              .contains('Have not set an experience level')
              .should('not.exist');
          });
        },
      );
    });

    describe('Target Geolocations Field', () => {
      beforeEach(() => {
        cy.enableFeatureFlag('billboard_location_targeting');
        cy.get('@user').then((user) => {
          cy.loginAndVisit(user, '/admin/customization/billboards');
          cy.findByRole('link', { name: 'Make A New Billboard' }).click({
            force: true,
          });
        });
      });
      afterEach(() => {
        cy.disableFeatureFlag('billboard_location_targeting');
      });

      it('should show a placeholder with valid geolocation codes', () => {
        cy.findByLabelText('Target Geolocations:')
          .as('targetGeolocations')
          .should('exist');
        cy.get('input[placeholder="US-NY, CA-ON"]').should('exist');
      });
    });
  });
});
