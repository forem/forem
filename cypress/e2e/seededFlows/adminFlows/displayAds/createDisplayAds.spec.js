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
  });
});
