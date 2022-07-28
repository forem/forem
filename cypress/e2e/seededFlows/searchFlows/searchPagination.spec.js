describe('Search pagination', () => {
  beforeEach(() => {
    cy.testSetup();
  });

  it('should show paginator indicator when articles are present', function () {
    cy.visit('/search?q=test&filters=class_name:Article');

    cy.findByRole('heading', { name: 'Test article' }).should('exist');

    cy.findByRole('group', { name: 'Pagination group of buttons' }).should(
      'be.visible',
    );
    cy.findByRole('group', { name: 'Pagination group of buttons' }).within(
      () => {
        cy.findByRole('button', { name: 'Page 1' }).should('exist');
      },
    );
  });

  it('should no show paginator indicator when articles are empty', function () {
    cy.visit('/search?q=empty%20search&filters=class_name:Article');

    cy.findByRole('main').within(() => {
      cy.contains('No results match that query').should('be.visible');
    });

    cy.findByRole('group', { name: 'Pagination group of buttons' }).should(
      'not.exist',
    );
  });
});
