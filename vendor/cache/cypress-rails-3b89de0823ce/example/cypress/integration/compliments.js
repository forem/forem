describe('Compliments', () => {
  beforeEach(() => {
    cy.request('/cypress_rails_reset_state')
    cy.visit('/compliments')
  })

  it('renders 3 fixtures + 1 custom compliment', () => {
    cy.get('input[value="You make cool things"]')
    cy.get('input[value="You are very kind"]')
    cy.get('input[value="You motivate others"]')
    cy.get('input[value="You are courageous"]')
  })

  it('lets me edit the compliments', () => {
    cy.get('input[value="You are very kind"]').clear().type('You are SUPER kind{enter}')

    // Shows a confirmation
    cy.contains('Yay, you saved a compliment!')

    // Shows the input with the new value
    cy.get('input[value="You are very kind"]').should('not.exist')
    cy.get('input[value="You are SUPER kind"]')
  })

  it('resets the compliments between each test case', () => {
    // Make sure the original compliment is still here
    cy.get('input[value="You are SUPER kind"]').should('not.exist')
    cy.get('input[value="You are very kind"]')

    // Still shows all 4 compliments
    cy.get('input[type=text]').should('have.length', 4)
  })

})
