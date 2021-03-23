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
    cy.intercept(
      { method: 'GET', url: '/search/usernames' },
      { fixture: 'search/usernames.json' },
    );

    cy.findByLabelText('Add a comment to the discussion').click();
    cy.findByRole('combobox');

    cy.findByLabelText('Add a comment to the discussion').as(
      'autocompleteCommentBox',
    );

    cy.get('@autocompleteCommentBox').type('Some text @s');
    cy.findByText('Type to search for a user').should('exist');

    cy.get('@autocompleteCommentBox').type('earch');

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
  });

  it('should select a mention autocomplete suggestion by keyboard', () => {
    cy.intercept(
      { method: 'GET', url: '/search/usernames' },
      { fixture: 'search/usernames.json' },
    );

    cy.findByLabelText('Add a comment to the discussion').click();
    cy.findByRole('combobox');

    cy.findByLabelText('Add a comment to the discussion').type(
      'Some text @search_user{downarrow}{enter}',
    );

    cy.findByDisplayValue('Some text @search_user_1').should('exist');
  });

  it('should accept entered comment text without user mention if no autocomplete suggestions', () => {
    cy.intercept(
      { method: 'GET', url: '/search/usernames' },
      { fixture: 'search/emptyUsernamesSearch.json' },
    );

    cy.findByLabelText('Add a comment to the discussion').click();
    cy.findByRole('combobox');

    cy.findByLabelText('Add a comment to the discussion').as(
      'autocompleteCommentBox',
    );

    cy.get('@autocompleteCommentBox').type('Some text @user');

    cy.findByText('No results found').should('exist');
    cy.get('@autocompleteCommentBox').type(' ');
    cy.findByText('No results found').should('not.exist');
    cy.findByDisplayValue('Some text @user').should('exist');
  });

  it('should stop showing mention autocomplete suggestions on text delete', () => {
    cy.intercept(
      { method: 'GET', url: '/search/usernames' },
      { fixture: 'search/usernames.json' },
    );

    cy.findByLabelText('Add a comment to the discussion').click();
    cy.findByRole('combobox');

    cy.findByLabelText('Add a comment to the discussion').as(
      'autocompleteCommentBox',
    );

    cy.get('@autocompleteCommentBox').type('Some text @se');
    cy.findByText('@search_user_1').should('exist');

    cy.get('@autocompleteCommentBox').type('{backspace}{backspace}{backspace}');
    cy.findByText('@search_user_1').should('not.exist');
  });

  it('should resume search suggestions when user types after deleting', () => {
    cy.intercept(
      { method: 'GET', url: '/search/usernames' },
      { fixture: 'search/usernames.json' },
    );

    cy.findByLabelText('Add a comment to the discussion').click();
    cy.findByRole('combobox');

    cy.findByLabelText('Add a comment to the discussion').as(
      'autocompleteCommentBox',
    );

    cy.get('@autocompleteCommentBox').type('Some text @se');
    cy.get('@autocompleteCommentBox').type('{backspace}{backspace}');
    cy.findByText('@search_user_1').should('not.exist');
    cy.get('@autocompleteCommentBox').type('se');
    cy.findByText('@search_user_1').should('exist');
  });

  it('should close the autocomplete suggestions on Escape press', () => {
    cy.intercept(
      { method: 'GET', url: '/search/usernames' },
      { fixture: 'search/usernames.json' },
    );

    cy.findByLabelText('Add a comment to the discussion').click();
    cy.findByRole('combobox');

    cy.findByLabelText('Add a comment to the discussion').as(
      'autocompleteCommentBox',
    );

    cy.get('@autocompleteCommentBox').type('Some text @search');
    cy.findByText('@search_user_1').should('be.visible');

    cy.get('@autocompleteCommentBox').type('{Esc}');
    cy.findByText('@search_user_1').should('not.be.visible');
  });

  it('should reply to a comment with user mention autocomplete', () => {
    cy.intercept(
      { method: 'GET', url: '/search/usernames' },
      { fixture: 'search/usernames.json' },
    );

    cy.findByLabelText('Add a comment to the discussion').click();
    cy.findByRole('combobox');

    cy.findByLabelText('Add a comment to the discussion').type('first comment');
    cy.findByRole('button', { name: /Submit/ }).click();

    cy.findByRole('link', { name: /Reply/ }).click();

    cy.findByRole('combobox', { name: /Reply to a comment/ }).as(
      'replyCombobox',
    );
    cy.get('@replyCombobox').click();
    cy.get('@replyCombobox').type('Some text @search_user');

    cy.findByText('@search_user_1').click();
    cy.findByDisplayValue('Some text @search_user_1');
  });
});
