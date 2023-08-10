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
        'Sidebar Right (Home)',
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
        cy.get('@audienceSegments')
          .select('Have not posted yet')
          .should('exist');
        cy.get('@audienceSegments')
          .select('Have not set an experience level')
          .should('exist');

        cy.get('@audienceSegments')
          .contains('Managed elsewhere')
          .should('not.exist');
      });

      context(
        'when editing a display ad with a manually managed audience',
        () => {
          beforeEach(() => {
            cy.visit('/admin/customization/billboards');
            cy.findByRole('link', { name: 'Manual Audience Billboard' }).click({
              force: true,
            });
          });

          it('shows the audience segment field but disabled', () => {
            cy.findByLabelText('Users who:')
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

      it('should not return iso3166 errors if given valid geolocation code inputs', () => {
        cy.findByRole('textbox', { name: 'Target Geolocations:' }).type(
          'CA-ON, US-OH, US-MI',
        );
        cy.findByRole('button', { name: 'Save Billboard' }).click();
        cy.get('#flash-0').should(($flashMessage) => {
          expect($flashMessage).to.not.contain(
            'is not a supported ISO 3166-2 code',
          );
        });
      });

      it('should generate errors if some or all of the input is invalid', () => {
        cy.findByRole('textbox', { name: 'Target Geolocations:' }).type(
          'US-NY, MX-CMX',
        );
        cy.findByRole('button', { name: 'Save Billboard' }).click();
        cy.get('#flash-0').should(($flashMessage) => {
          // We currently support only the US and CA
          expect($flashMessage).to.contain(
            'MX-CMX is not a supported ISO 3166-2 code',
          );
          expect($flashMessage).to.not.contain(
            'US-NY is not a supported ISO 3166-2 code',
          );
        });
      });
    });
  });
});
