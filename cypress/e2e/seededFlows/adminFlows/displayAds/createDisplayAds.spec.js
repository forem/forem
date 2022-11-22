describe('Create Display Ads', () => {
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

    it('should not show the tags field if the placement is not "Below the comment section"', () => {
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
  });
});
