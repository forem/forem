describe('View tag adjustments', () => {
  describe('from /mod page', () => {
    beforeEach(() => {
      cy.testSetup();
      cy.fixture('users/adminUser.json').as('user');

      cy.get('@user').then((user) => {
        cy.loginAndVisit(user, '/mod');
      });
    });

    // Helper function for pipe command
    const click = ($el) => $el.click();

    // Disabling for now as the flake rate from timeouts and missed elements is affecting
    // the pace of reviewing and merging other work.
    it('should show previous tag adjustments', () => {
      cy.findByRole('heading', { name: 'Tag test article' }).click();

      cy.getIframeBody('.actions-panel-iframe').within(() => {
        cy.findByRole('button', {
          name: 'Open adjust tags section',
        })
          .pipe(click)
          .should('have.attr', 'aria-expanded', 'true');

        cy.get('#tag-history-heading').scrollIntoView();
        cy.get('#tag-adjustment-history')
          .find('.tag-adjustment')
          .should(($div) => {
            expect($div[0].innerText).to.contain(
              '# tag1 added by Admin McAdmin\nadding test tag 1',
            );
            expect($div[1].innerText).to.contain(
              '# tag2 added by Admin McAdmin\nadding test tag 2',
            );
          });
      });
    });
  });
});
