describe('Navigate User Tabs', () => {
  describe('As an admin', () => {
    beforeEach(() => {
      cy.testSetup();
      cy.fixture('users/adminUser.json').as('user');
      cy.get('@user').then((user) => {
        cy.loginAndVisit(user, '/admin/member_manager/users/2');
      });
    });

    it(`navigates to the "Overview" tab`, () => {
      cy.findByRole('navigation', { name: 'Member details' }).within(() => {
        cy.findByRole('link', { name: /Overview/i }).should('exist');
        cy.findByRole('link', { name: /Overview/i }).click();
        cy.url().should('not.contain', 'tab=');
      });
    });

    it(`navigates to the "Notes" tab`, () => {
      cy.findByRole('link', { name: /Notes/i }).should('exist');
      cy.findByRole('link', { name: /Notes/i }).click();
      cy.url().should('contain', '/admin/member_manager/users/2?tab=notes');
    });

    it(`navigates to the "Emails" tab`, () => {
      cy.findByRole('link', { name: /Emails/i }).should('exist');
      cy.findByRole('link', { name: /Emails/i }).click();
      cy.url().should('contain', '/admin/member_manager/users/2?tab=emails');
    });

    it(`navigates to the "Reports" tab`, () => {
      cy.findByRole('link', { name: /Reports/i }).should('exist');
      cy.findByRole('link', { name: /Reports/i }).click();
      cy.url().should('contain', '/admin/member_manager/users/2?tab=reports');
    });

    it(`navigates to the "Flags" tab`, () => {
      cy.findByRole('link', { name: /Flags/i }).should('exist');
      cy.findByRole('link', { name: /Flags/i }).click();
      cy.url().should('contain', '/admin/member_manager/users/2?tab=flags');
    });
  });
});
