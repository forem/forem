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

    // Wait for the new autocomplete text areas to be mounted
    cy.findByTestId('autocomplete-textarea', {
      role: 'textbox',
      name: /Add a comment to the discussion/,
    }).as('plainCommentBox');
    cy.get('@plainCommentBox').type('Some text @s');

    // Verify the combobox has appeared
    cy.findByRole('combobox', { name: /Add a comment to the discussion/ }).as(
      'autocompleteCommentBox',
    );
    cy.get('@autocompleteCommentBox').should('have.focus');

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

    cy.get('@plainCommentBox').should('have.focus');
    cy.get('@plainCommentBox').should(
      'have.value',
      'Some text @search_user_3 ',
    );
  });

  it('should select a mention autocomplete suggestion by keyboard', () => {
    cy.intercept(
      { method: 'GET', url: '/search/usernames' },
      { fixture: 'search/usernames.json' },
    );

    cy.findByLabelText('Add a comment to the discussion').click();

    // Wait for the new autocomplete text areas to be mounted
    cy.findByTestId('autocomplete-textarea', {
      role: 'textbox',
      name: /Add a comment to the discussion/,
    }).as('plainCommentBox');

    cy.get('@plainCommentBox').type('Some text @s');
    // Verify the combobox has appeared
    cy.findByRole('combobox', { name: /Add a comment to the discussion/ }).as(
      'autocompleteCommentBox',
    );
    cy.get('@autocompleteCommentBox').should('have.focus');
    cy.get('@autocompleteCommentBox').type('earch_user{downarrow}{enter}');

    cy.get('@plainCommentBox').should('have.focus');
    cy.get('@plainCommentBox').should(
      'have.value',
      'Some text @search_user_1 ',
    );
  });

  it('should accept entered comment text without user mention if no autocomplete suggestions', () => {
    cy.intercept(
      { method: 'GET', url: '/search/usernames' },
      { fixture: 'search/emptyUsernamesSearch.json' },
    );

    cy.findByLabelText('Add a comment to the discussion').click();
    // Wait for the new autocomplete text areas to be mounted
    cy.findByTestId('autocomplete-textarea', {
      role: 'textbox',
      name: /Add a comment to the discussion/,
    }).as('plainCommentBox');

    cy.get('@plainCommentBox').type('Some text @u');
    // Verify the combobox has appeared
    cy.findByRole('combobox', { name: /Add a comment to the discussion/ }).as(
      'autocompleteCommentBox',
    );
    cy.get('@autocompleteCommentBox').should('have.focus');

    cy.get('@autocompleteCommentBox').type('ser');

    cy.findByText('No results found').should('exist');
    cy.get('@autocompleteCommentBox').type(' ');

    cy.findByText('No results found').should('not.exist');
    cy.get('@plainCommentBox').should('have.focus');
    cy.get('@plainCommentBox').should('have.value', 'Some text @user ');
  });

  it('should stop showing mention autocomplete suggestions on text delete', () => {
    cy.intercept(
      { method: 'GET', url: '/search/usernames' },
      { fixture: 'search/usernames.json' },
    );

    cy.findByLabelText('Add a comment to the discussion').click();
    // Wait for the new autocomplete text areas to be mounted
    cy.findByTestId('autocomplete-textarea', {
      role: 'textbox',
      name: /Add a comment to the discussion/,
    }).as('plainCommentBox');

    cy.get('@plainCommentBox').type('Some text @s');
    // Verify the combobox has appeared
    cy.findByRole('combobox', { name: /Add a comment to the discussion/ }).as(
      'autocompleteCommentBox',
    );

    cy.get('@autocompleteCommentBox').should('have.focus');
    cy.get('@autocompleteCommentBox').type('e');
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
    // Wait for the new autocomplete text areas to be mounted
    cy.findByTestId('autocomplete-textarea', {
      role: 'textbox',
      name: /Add a comment to the discussion/,
    }).as('plainCommentBox');

    cy.get('@plainCommentBox').type('Some text @se');

    // Verify the combobox has appeared
    cy.findByRole('combobox', { name: /Add a comment to the discussion/ }).as(
      'autocompleteCommentBox',
    );

    cy.get('@autocompleteCommentBox').should('have.focus');
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
    // Wait for the new autocomplete text areas to be mounted
    cy.findByTestId('autocomplete-textarea', {
      role: 'textbox',
      name: /Add a comment to the discussion/,
    }).as('plainCommentBox');
    cy.get('@plainCommentBox').type('Some text @s');

    // Verify the combobox has appeared
    cy.findByRole('combobox', { name: /Add a comment to the discussion/ }).as(
      'autocompleteCommentBox',
    );

    cy.get('@autocompleteCommentBox').type('earch');
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
    // Wait for the new autocomplete text areas to be mounted
    cy.findByTestId('autocomplete-textarea', {
      role: 'textbox',
      name: /Add a comment to the discussion/,
    }).as('plainCommentBox');

    cy.get('@plainCommentBox').type('first comment');
    cy.findByRole('button', { name: /Submit/ }).click();

    cy.findByRole('link', { name: /Reply/ }).click();

    cy.findAllByTestId('autocomplete-textarea', {
      role: 'textbox',
      name: /Reply to a comment/,
    })
      .last()
      .as('replyCommentBox');

    cy.get('@replyCommentBox').click();
    cy.get('@replyCommentBox').type('Some text @s');

    // Verify the combobox has appeared
    cy.findByRole('combobox', { name: /Reply to a comment/ }).as(
      'autocompleteCommentBox',
    );

    cy.get('@autocompleteCommentBox').type('earch');
    cy.findByText('@search_user_1').click();

    cy.get('@replyCommentBox').should(
      'have.value',
      'Some text @search_user_1 ',
    );
  });

  it('should pre-populate a comment field when editing', () => {
    cy.intercept(
      { method: 'GET', url: '/search/usernames' },
      { fixture: 'search/usernames.json' },
    );

    cy.findByLabelText('Add a comment to the discussion').click();
    // Wait for the new autocomplete text areas to be mounted
    cy.findByTestId('autocomplete-textarea', {
      role: 'textbox',
      name: /Add a comment to the discussion/,
    }).as('plainCommentBox');

    cy.get('@plainCommentBox').type('first comment');
    cy.findByRole('button', { name: /Submit/ }).click();

    cy.findByRole('link', { name: /Reply/ });

    cy.findByTestId('comments-container').within(() => {
      cy.findByLabelText('Toggle dropdown menu').click();
      // Wait for the menu to be visible
      cy.findByText('Edit').should('be.visible');
      cy.findByText('Edit').click();
    });

    cy.findByDisplayValue('first comment').should('exist');
  });
});
