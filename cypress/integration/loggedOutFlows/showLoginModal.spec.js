describe('Show log in modal', () => {
  beforeEach(() => {
    cy.testSetup();
    cy.visit('/');
  });

  it('should show a log in modal on Feed bookmark click', () => {
    cy.findAllByRole('button', { name: /Save/ }).first().as('bookmarkButton');

    cy.get('@bookmarkButton').click();

    cy.findByTestId('modal-container').as('modal');
    cy.get('@modal').findByText('Log in to continue').should('exist');
    cy.get('@modal').findByLabelText('Log in').should('exist');
    cy.get('@modal').findByLabelText('Create new account').should('exist');
    cy.get('@modal').findByRole('button').first().should('have.focus');

    cy.get('@modal').findByRole('button', { name: /Close/ }).click();
    cy.get('@bookmarkButton').should('have.focus');
    cy.findByTestId('modal-container').should('not.exist');
  });

  it('should show login modal for article reaction clicks', () => {
    cy.findAllByText('Test article').last().click();

    cy.findByRole('checkbox', { name: 'Heart' }).as('heartReaction');
    cy.findByRole('checkbox', { name: 'Unicorn' }).as('unicornReaction');
    cy.findByRole('checkbox', { name: 'Saved' }).as('bookmarkReaction');

    ['@heartReaction', '@unicornReaction', '@bookmarkReaction'].forEach(
      (reaction) => {
        cy.get(reaction).click();

        cy.findByTestId('modal-container').as('modal');
        cy.get('@modal').findByText('Log in to continue').should('exist');
        cy.get('@modal').findByLabelText('Log in').should('exist');
        cy.get('@modal').findByLabelText('Create new account').should('exist');
        cy.get('@modal').findByRole('button').first().should('have.focus');

        cy.get('@modal').findByRole('button', { name: /Close/ }).click();
        cy.get(reaction).should('have.focus');
        cy.findByTestId('modal-container').should('not.exist');
      },
    );
  });

  it('should show login modal for comment subscription', () => {
    cy.findAllByText('Test article').last().click();
    cy.findByRole('button', { name: /Subscribe/ }).as('subscribe').click();

    cy.findByTestId('modal-container').as('modal');
    cy.get('@modal').findByText('Log in to continue').should('exist');
    cy.get('@modal').findByLabelText('Log in').should('exist');
    cy.get('@modal').findByLabelText('Create new account').should('exist');
    cy.get('@modal').findByRole('button').first().should('have.focus');

    cy.get('@modal').findByRole('button', { name: /Close/ }).click();
    cy.get('@subscribe').should('have.focus');
    cy.findByTestId('modal-container').should('not.exist');
  });
});
