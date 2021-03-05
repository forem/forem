describe('Comment on articles', () => {
  beforeEach(() => {
    cy.testSetup();
    cy.fixture('users/articleEditorV1User.json').as('user');

    cy.get('@user').then((user) => {
      cy.loginUser(user).then(() => {
        cy.visit('/');
        cy.findAllByText('Test article').last().click();
      });
    });
  });

  it('should comment on an article with user mention autocomplete suggesting max 6 users', () => {
    cy.findByLabelText('Add a comment to the discussion').as('commentBox');
    startAutocompleteInTextArea('@commentBox');

    cy.findByLabelText('mention user').as('comboboxHiddenInput');
    cy.get('@comboboxHiddenInput').should('have.focus');

    cy.get('@comboboxHiddenInput').type('s');
    cy.findByText('Type to search for a user').should('exist');

    cy.get('@comboboxHiddenInput').type('earch');

    const expectedUsernames = [
      '@search_user_1',
      '@search_user_2',
      '@search_user_2',
      '@search_user_3',
      '@search_user_4',
      '@search_user_5',
      '@search_user_6',
    ];

    expectedUsernames.forEach((name) => cy.findByText(name).should('exist'));
    cy.findByText('@search_user_7').should('not.exist');

    cy.findByText('@search_user_3').click();
    cy.findByDisplayValue('Some text @search_user_3').should('exist');

    cy.findByRole('button', { name: /Submit/ }).click();
    cy.findByRole('link', { name: /@search_user_3/ }).should('exist');
  });

  it('should select a mention autocomplete suggestion by keyboard', () => {
    cy.findByLabelText('Add a comment to the discussion').as('commentBox');
    startAutocompleteInTextArea('@commentBox');

    cy.findByLabelText('mention user').as('comboboxHiddenInput');
    cy.get('@comboboxHiddenInput').should('have.focus');

    cy.get('@comboboxHiddenInput').type('search_user_1');
    cy.get('@comboboxHiddenInput').type('{downarrow}');
    cy.get('@comboboxHiddenInput').type('{enter}');

    cy.findByDisplayValue('Some text @search_user_1').should('exist');
  });

  it('should accept entered comment text without user mention if no autocomplete suggestions', () => {
    cy.findByLabelText('Add a comment to the discussion').as('commentBox');
    startAutocompleteInTextArea('@commentBox');

    cy.findByLabelText('mention user').as('comboboxHiddenInput');
    cy.get('@comboboxHiddenInput').should('have.focus');

    cy.get('@comboboxHiddenInput').type('user');

    cy.findByText('No results found').should('exist');
    cy.get('@comboboxHiddenInput').type(' ');
    cy.findByText('No results found').should('not.exist');

    cy.findByRole('button', { name: /Submit/ }).click();
    cy.findByRole('link', { name: /@user/ }).should('not.exist');
    cy.findByDisplayValue('Some text @user').should('exist');
  });

  it('should update mention autocomplete suggestions on text delete', () => {
    cy.findByLabelText('Add a comment to the discussion').as('commentBox');
    startAutocompleteInTextArea('@commentBox');

    cy.findByLabelText('mention user').as('comboboxHiddenInput');
    cy.get('@comboboxHiddenInput').should('have.focus');

    cy.get('@comboboxHiddenInput').type('search_user_1');
    cy.findByText('@search_user_1').should('exist');
    cy.findByText('@search_user_2').should('not.exist');

    cy.get('@comboboxHiddenInput').type('{backspace}');
    cy.findByText('@search_user_2').should('exist');
  });

  it('should close the autocomplete suggestions on Escape press', () => {
    cy.findByLabelText('Add a comment to the discussion').as('commentBox');
    startAutocompleteInTextArea('@commentBox');

    cy.findByLabelText('mention user').as('comboboxHiddenInput');
    cy.get('@comboboxHiddenInput').should('have.focus');

    cy.get('@comboboxHiddenInput').type('search');
    cy.findByText('@search_user_1').should('be.visible');

    cy.get('@comboboxHiddenInput').type('{Esc}');
    cy.findByText('@search_user_1').should('not.be.visible');
  });

  it('should reply to a comment with user mention autocomplete', () => {
    cy.findByLabelText('Add a comment to the discussion').as('commentBox');
    cy.get('@commentBox').type('first comment');
    cy.findByRole('button', { name: /Submit/ }).click();

    cy.findByRole('link', { name: /Reply/ }).click();
    cy.findByLabelText('Reply to a comment...').as('replyCommentBox');

    startAutocompleteInTextArea('@replyCommentBox');

    cy.findByLabelText('mention user').as('comboboxHiddenInput');
    cy.get('@comboboxHiddenInput').should('have.focus');
    cy.get('@comboboxHiddenInput').type('search_user');

    cy.findByText('@search_user_1').click();
    cy.findByRole('button', { name: /Submit/ }).click();
    cy.findByRole('link', { name: /@search_user_1/ }).should('exist');
  });

  const startAutocompleteInTextArea = (textAreaSelector) => {
    //   Extra click is a workaround for https://github.com/cypress-io/cypress/issues/5023
    cy.get(textAreaSelector).click();
    cy.get(textAreaSelector).focus();
    cy.get(textAreaSelector).type('Some text @');
  };
});
