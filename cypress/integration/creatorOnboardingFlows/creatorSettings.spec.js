describe('Creator Settings Page', () => {
  const { baseUrl } = Cypress.config();

  beforeEach(() => {
    cy.testSetup();
    cy.fixture('users/creatorUser.json').as('creator');
    cy.get('@creator').then((creator) => {
      cy.loginCreator(creator);
    });

    cy.visit(`${baseUrl}admin/creator_settings/new`);
  });

  it('should submit the creator settings form', () => {
    // should display a welcome message
    cy.findByText("Lovely! Let's set up your Forem.").should('be.visible');
    cy.findByText('No stress, you can always change it later.').should(
      'be.visible',
    );
    cy.findByText(
      /Setup not completed yet, missing community description, suggested tags, and suggested users./i,
    ).should('not.be.visible');

    // should contain a community name and update the field properly
    cy.findByRole('textbox', { name: /community name/i })
      .as('communityName')
      .invoke('attr', 'placeholder')
      .should('eq', 'Climbing Life');
    cy.get('@communityName').type('Climbing Life');

    // should contain a logo upload field and upload a logo upon click
    cy.findByLabelText(/logo/i, { selector: 'input' }).attachFile(
      '/images/admin-image.png',
    );
    cy.findByRole('img', { name: /preview of logo selected/i }).should(
      'be.visible',
    );

    // should contain a brand color field
    cy.findByText(/^Brand color/).should('be.visible');
    cy.findByText(/^Brand color/).invoke('attr', 'value', '#ff0000');

    // should contain a 'Who can join this community?' radio selector field and allow selection upon click
    cy.findByRole('group', { name: /^Who can join this community/i }).should(
      'be.visible',
    );
    cy.findAllByRole('radio', { name: /everyone/i }).check();
    cy.findAllByRole('radio').should('be.checked');

    // should contain a 'Who can view content in this community?' radio selector field and allow selection upon click
    cy.findByRole('group', {
      name: /^Who can view content in this community/i,
    }).should('be.visible');
    cy.findAllByRole('radio', { name: /members only/i }).check();
    cy.findAllByRole('radio').should('be.checked');

    // should contain a 'I agree to uphold our Code of Conduct' checkbox field and allow selection upon click
    cy.findByRole('group', {
      name: /^finally, please agree to the following:/i,
    }).should('be.visible');
    cy.findAllByRole('checkbox').first().check();
    cy.findAllByRole('checkbox').should('be.checked');

    // should contain a 'I agree to our Terms and Conditions' checkbox field and allow selection upon click
    cy.findByRole('group', {
      name: /^finally, please agree to the following:/i,
    }).should('be.visible');
    cy.findAllByRole('checkbox').eq(1).check();
    cy.findAllByRole('checkbox').should('be.checked');

    // should redirect the creator to the home page when the form is completely filled out and 'Finish' is clicked
    cy.findByRole('button', { name: 'Finish' }).click();
    cy.url().should('equal', baseUrl);
  });

  it('should update the colors on the form when a new brand color is selected', () => {
    const color = '#25544b';
    const rgbColor = 'rgb(37, 84, 75)';

    cy.findByLabelText(/^Brand color/)
      .clear()
      .type(color)
      .trigger('change');

    cy.findByRole('button', { name: 'Finish' }).should(
      'have.css',
      'background-color',
      rgbColor,
    );

    cy.findAllByRole('radio', { name: /members only/i })
      .check()
      .should('have.css', 'background-color', rgbColor)
      .should('have.css', 'border-color', rgbColor);

    cy.findByRole('textbox', { name: /community name/i })
      .focus()
      .should('have.css', 'border-color', rgbColor);

    cy.findByRole('link', { name: /Forem Admin Guide/i }).should(
      'have.css',
      'background-color',
      rgbColor,
    );
  });

  it('should not submit the creator settings form if any of the fields are not filled out', () => {
    // TODO: Circle back around to testing this once the styling for the form is complete
    cy.findByRole('textbox', { name: /community name/i }).should(
      'have.attr',
      'required',
    );

    cy.findByLabelText(/logo/i, { selector: 'input' }).should(
      'have.attr',
      'required',
    );

    // should not redirect the creator to the home page when the form is not completely filled out and 'Finish' is clicked
    cy.findByRole('button', { name: 'Finish' }).click();
    cy.url().should('equal', `${baseUrl}admin/creator_settings/new`);
  });
});
