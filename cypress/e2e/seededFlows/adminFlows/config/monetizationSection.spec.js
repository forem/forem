describe('Monetization section', () => {
  beforeEach(() => {
    cy.testSetup();
    cy.fixture('users/adminUser.json').as('user');
    cy.get('@user').then((user) => cy.loginUser(user));
  });

  function withinMonetizationSection(callback) {
    cy.findByText('Monetization')
      .as('monetizationSectionHeader')
      .parent()
      .within(() => {
        cy.get('@monetizationSectionHeader').click();
        callback();
      });
  }

  context('when location targeting is not enabled', () => {
    beforeEach(() => {
      cy.visit('/admin/customization/config');
    });

    it('does not show countries for billboard geotargeting', () => {
      withinMonetizationSection(() => {
        cy.findByText('Billboard enabled countries').should('not.exist');
        cy.findByRole('combobox').should('not.exist');
        cy.findByLabelText('Enabled countries for targeting').should(
          'not.exist',
        );
      });
    });
  });

  context('when location targeting is enabled', () => {
    beforeEach(() => {
      cy.enableFeatureFlag('billboard_location_targeting');
      cy.visit('/admin/customization/config');
    });

    it('autocompletes countries for selection', () => {
      withinMonetizationSection(() => {
        cy.findByText('Billboard enabled countries').should('exist');

        cy.findByLabelText('Enabled countries for targeting').as('textbox');
        cy.findByRole('listbox').should('not.exist');

        cy.get('@textbox').type('ger');
        cy.findByRole('listbox')
          .should('contain.text', 'Germany')
          .should('contain.text', 'Algeria')
          .should('contain.text', 'Niger')
          .should('contain.text', 'Nigeria');

        cy.get('@textbox').clear();
        cy.findByRole('listbox').should('not.exist');

        cy.get('@textbox').type('IND');
        cy.findByRole('listbox')
          .should('contain.text', 'Indonesia')
          .should('contain.text', 'India');

        cy.get('@textbox').clear();
        cy.findByRole('listbox').should('not.exist');

        cy.get('@textbox').type('Uni');
        cy.findByRole('listbox')
          .should('contain.text', 'Réunion')
          .should('contain.text', 'Tunisia')
          .should('contain.text', 'United Arab Emirates')
          .should('contain.text', 'United Kingdom');
      });
    });

    it('allows the user to select and deselect countries', () => {
      withinMonetizationSection(() => {
        cy.findByRole('combobox')
          .as('selections')
          .findByLabelText('France')
          .should('not.exist');
        cy.get('@selections').findByLabelText('Canada').should('exist');
        cy.get('@selections').findByLabelText('United States').should('exist');

        cy.findByLabelText('Enabled countries for targeting').type('Fra');
        cy.findByRole('listbox').findByText('France').click();
        cy.get('@selections').findByLabelText('France').should('exist');
        cy.get('@selections').findByLabelText('Canada').should('exist');
        cy.get('@selections').findByLabelText('United States').should('exist');

        cy.findByRole('button', { name: 'Remove Canada' }).click();
        cy.get('@selections').findByLabelText('France').should('exist');
        cy.get('@selections').findByLabelText('Canada').should('not.exist');
        cy.get('@selections').findByLabelText('United States').should('exist');

        cy.findByRole('button', { name: 'Update Settings' }).click();
      });

      cy.findByTestId('snackbar')
        .should('be.visible')
        .should('have.text', 'Successfully updated settings.');

      cy.reload();
      withinMonetizationSection(() => {
        cy.findByRole('combobox').as('selections');
        cy.get('@selections').findByLabelText('France').should('exist');
        cy.get('@selections').findByLabelText('Canada').should('not.exist');
        cy.get('@selections').findByLabelText('United States').should('exist');
      });
    });

    it('allows the user to enable and disable region targeting', () => {
      const toggle = (country, { expectedText }) => {
        cy.get('@selections')
          .findByRole('group', { name: country })
          .findByRole('button', { name: 'Toggle region targeting' })
          .click();

        cy.get('@selections')
          .findByRole('group', { name: country })
          .should('contain.text', expectedText);
      };

      withinMonetizationSection(() => {
        cy.findByRole('combobox').as('selections');
        cy.get('@selections')
          .findByRole('group', { name: 'United States' })
          .should('contain.text', 'Including regions');
        cy.get('@selections')
          .findByRole('group', { name: 'Canada' })
          .should('contain.text', 'Including regions');

        toggle('United States', { expectedText: 'Excluding regions' });
        toggle('United States', { expectedText: 'Including regions' });

        toggle('Canada', { expectedText: 'Excluding regions' });

        cy.findByRole('button', { name: 'Update Settings' }).click();
      });

      cy.findByTestId('snackbar')
        .should('be.visible')
        .should('have.text', 'Successfully updated settings.');

      cy.reload();
      withinMonetizationSection(() => {
        cy.findByRole('combobox').as('selections');
        cy.get('@selections')
          .findByRole('group', { name: 'United States' })
          .should('contain.text', 'Including regions');
        cy.get('@selections')
          .findByRole('group', { name: 'Canada' })
          .should('contain.text', 'Excluding regions');
      });
    });
  });
});
