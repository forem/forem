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
    });
  });
});
