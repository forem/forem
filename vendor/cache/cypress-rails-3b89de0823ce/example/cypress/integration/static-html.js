/// <reference types="Cypress" />
context('Static HTML with no database stuff', () => {
  it('Fills a form', () => {
    cy.visit('/an_static_form')
    cy.get('#name').type('Human Person')
    cy.get('#age').select('30-40')
    cy.get('input[value=cypress]').check()

    cy.get('#name').should('have.value', 'Human Person')
    cy.get('#age').should('have.value', '30')
    cy.get('input[value=cypress]').should('be.checked')
  })
})
