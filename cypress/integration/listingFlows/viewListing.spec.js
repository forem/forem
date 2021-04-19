describe('View listing', () => {
  beforeEach(() => {
    cy.testSetup();
    cy.viewport('macbook-16');
    cy.visit('/');
  });

  it('opens a listing from the Feed page', () => {
    cy.findByText('Listing title').click();
    cy.findByTestId('listings-modal').as('listingsModal');

    cy.get('@listingsModal').findByText('Listing').should('exist');
    cy.get('@listingsModal').findByText('Listing title').should('exist');
    cy.get('@listingsModal')
      .findAllByRole('button')
      .first()
      .should('have.focus');

    cy.get('@listingsModal').findByRole('button', { name: /Close/ }).click();
    cy.get('@listingsModal').should('not.exist');
  });

  it('opens a listing from the listings page', () => {
    cy.intercept(
      '/search/listings?category=&listing_search=&page=0&per_page=75&tag_boolean_mode=all',
      { fixture: 'search/listings.json' },
    );

    cy.visit('/listings');

    cy.findByRole('link', { name: 'Listing title' }).as('listingTitle');
    cy.get('@listingTitle').click();

    cy.findByTestId('listings-modal').as('listingsModal');
    cy.get('@listingsModal').findByText('Listing').should('exist');
    cy.get('@listingsModal').findByText('Listing title').should('exist');
    cy.get('@listingsModal')
      .findAllByRole('button')
      .first()
      .should('have.focus');

    cy.get('@listingsModal').findByRole('button', { name: /Close/ }).click();
    cy.get('@listingTitle').should('have.focus');
  });
});
