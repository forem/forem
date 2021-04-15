describe('Comment on articles', () => {
  beforeEach(() => {
    cy.testSetup();
    cy.fixture('users/articleEditorV1User.json').as('user');

    cy.get('@user').then((user) => {
      cy.loginUser(user).then(() => {
        cy.createArticle({
          title: 'Test Article',
          tags: ['beginner', 'ruby', 'go'],
          content: `This is a test article's contents.`,
          published: true,
        }).then((response) => {
          cy.visit(response.body.current_state_path);
        });
      });
    });
  });

  describe('Comments using mention autocomplete', () => {
    it.skip('should comment on an article with user mention autocomplete suggesting max 6 users', () => {
      cy.intercept(
        { method: 'GET', url: '/search/usernames' },
        { fixture: 'search/usernames.json' },
      );

      cy.findByLabelText(/^Add a comment to the discussion$/i).click();

      // Get a handle to the newly substituted textbox
      cy.findByRole('textbox', {
        name: /^Add a comment to the discussion$/i,
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

      cy.findByLabelText(/^Add a comment to the discussion$/i).click();

      // Get a handle to the newly substituted textbox
      cy.findByRole('textbox', {
        name: /^Add a comment to the discussion$/i,
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

      cy.findByLabelText(/^Add a comment to the discussion$/i).click();

      // Get a handle to the newly substituted textbox
      cy.findByRole('textbox', {
        name: /^Add a comment to the discussion$/i,
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

      cy.findByLabelText(/^Add a comment to the discussion$/i).click();

      // Get a handle to the newly substituted textbox
      cy.findByRole('textbox', {
        name: /^Add a comment to the discussion$/i,
      }).as('plainCommentBox');

      cy.get('@plainCommentBox').type('Some text @s');
      // Verify the combobox has appeared
      cy.findByRole('combobox', { name: /Add a comment to the discussion/ }).as(
        'autocompleteCommentBox',
      );

      cy.get('@autocompleteCommentBox').should('have.focus');
      cy.get('@autocompleteCommentBox').type('e');
      cy.findByText('@search_user_1').should('exist');

      cy.get('@autocompleteCommentBox').type(
        '{backspace}{backspace}{backspace}',
      );
      cy.findByText('@search_user_1').should('not.exist');
    });

    it('should resume search suggestions when user types after deleting', () => {
      cy.intercept(
        { method: 'GET', url: '/search/usernames' },
        { fixture: 'search/usernames.json' },
      );

      cy.findByLabelText(/^Add a comment to the discussion$/i).click();

      // Get a handle to the newly substituted textbox
      cy.findByRole('textbox', {
        name: /^Add a comment to the discussion$/i,
      }).type('Some text @se');

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

      cy.findByLabelText(/^Add a comment to the discussion$/i).click();

      // Get a handle to the newly substituted textbox
      cy.findByRole('textbox', {
        name: /^Add a comment to the discussion$/i,
      }).type('Some text @s');

      // Verify the combobox has appeared
      cy.findByRole('combobox', { name: /Add a comment to the discussion/ }).as(
        'autocompleteCommentBox',
      );

      cy.get('@autocompleteCommentBox').type('earch');
      cy.findByText('@search_user_1').should('be.visible');

      cy.get('@autocompleteCommentBox').type('{Esc}');
      cy.findByText('@search_user_1').should('not.be.visible');
    });

    it('should close the autocomplete suggestions and exit combobox on click outside', () => {
      cy.intercept(
        { method: 'GET', url: '/search/usernames' },
        { fixture: 'search/usernames.json' },
      );

      cy.findByLabelText(/^Add a comment to the discussion$/i).click();

      // Get a handle to the newly substituted textbox
      cy.findByRole('textbox', {
        name: /^Add a comment to the discussion$/i,
      }).as('plainTextArea');

      cy.get('@plainTextArea').type('Some text @s');

      // Verify the combobox has appeared
      cy.findByRole('combobox', { name: /Add a comment to the discussion/ }).as(
        'autocompleteCommentBox',
      );

      cy.get('@autocompleteCommentBox').type('earch');
      cy.findByText('@search_user_1').should('be.visible');

      // Click away from the dropdown
      cy.get('@autocompleteCommentBox').click({ position: 'right' });
      cy.findByText('@search_user_1').should('not.exist');

      // Check the combobox has exited and we are returned to the plainTextArea
      cy.get('@plainTextArea').should('have.focus');
    });

    it('should exit combobox when blurred and refocused', () => {
      cy.intercept(
        { method: 'GET', url: '/search/usernames' },
        { fixture: 'search/usernames.json' },
      );

      cy.findByLabelText(/^Add a comment to the discussion$/i).click();

      // Get a handle to the newly substituted textbox
      cy.findByRole('textbox', {
        name: /^Add a comment to the discussion$/i,
      }).as('plainTextArea');

      cy.get('@plainTextArea').type('Some text @s');

      // Verify the combobox has appeared
      cy.findByRole('combobox', {
        name: /Add a comment to the discussion/,
      }).as('combobox');

      // Blur the currently active textarea, and check that the blur results in the plainTextArea being restored
      cy.get('@combobox').blur();
      cy.get('@combobox').should('not.be.visible');
      cy.get('@plainTextArea').should('be.visible');
    });

    it.skip('should reply to a comment with user mention autocomplete', () => {
      cy.intercept(
        { method: 'GET', url: '/search/usernames' },
        { fixture: 'search/usernames.json' },
      );

      // Get a handle to the newly substituted textbox
      cy.findByRole('main')
        .as('main')
        .findByRole('textbox', /^Add a comment to the discussion$/i)
        .click();

      // The mention autocomplete is two textareas
      // and initially it's replacing the server-side rendered one,
      // so we need to get it again to be certain we have the correct reference.
      cy.get('@main')
        .findByRole('textbox', /^Add a comment to the discussion$/i)
        .type('first comment');

      cy.get('@main')
        .findByRole('button', { name: /^Submit$/i })
        .click();

      cy.get('@main')
        .findByRole('link', { name: /^Reply$/i })
        .click();

      cy.get('@main')
        .findByRole('textbox', {
          name: /^Reply to a comment\.\.\.$/,
        })
        .click();

      cy.get('@main')
        .findByRole('textbox', {
          name: /^Reply to a comment\.\.\.$/,
        })
        .as('replyCommentBox')
        .type('Some text @s');

      // Verify the combobox has appeared
      cy.get('@main')
        .findByRole('combobox', { name: /^Reply to a comment\.\.\.$/ })
        .as('autocompleteCommentBox');

      cy.get('@main').get('@autocompleteCommentBox').type('earch');
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

      cy.findByLabelText(/^Add a comment to the discussion$/i).click();
      // Get a handle to the newly substituted textbox
      cy.findByRole('textbox', {
        name: /^Add a comment to the discussion$/i,
      }).type('first comment');

      cy.findByRole('button', { name: /Submit/ }).click();
      cy.findByRole('link', { name: /Reply/ });

      cy.findByTestId('comments-container').within(() => {
        cy.findByRole('button', { name: 'Toggle dropdown menu' }).click();
        // Wait for the menu to be visible
        cy.findByText('Edit').should('be.visible');
        cy.findByText('Edit').click();
      });

      cy.findByDisplayValue('first comment').should('exist');
    });
  });

  it('should add a comment', () => {
    cy.findByRole('main')
      .as('main')
      .findByRole('heading', { name: 'Discussion (0)' });
    cy.get('@main')
      .findByRole('textbox', { name: /^Add a comment to the discussion$/i })
      .focus() // Focus activates the Submit button and mini toolbar below a comment textbox
      .type('this is a comment');

    cy.get('@main')
      .findByRole('textbox', { name: /^Add a comment to the discussion$/i })
      .should('have.value', 'this is a comment');

    cy.get('@main')
      .findByRole('button', { name: /^Submit$/i })
      .click();

    // Comment was saved so the new comment textbox should be empty.
    cy.get('@main')
      .findByRole('textbox', { name: /^Add a comment to the discussion$/i })
      .should('have.value', '');

    cy.get('@main').findByText(/^this is a comment$/i);
    cy.get('@main').findByRole('heading', { name: 'Discussion (1)' });
  });

  it('should add a comment from a response template', () => {
    cy.createResponseTemplate({
      title: 'Test Canned Response',
      content: 'This is a test canned response',
    }).then((_response) => {
      cy.findByRole('main')
        .as('main')
        .findByRole('heading', { name: 'Discussion (0)' });
      cy.get('@main')
        .findByRole('textbox', { name: /^Add a comment to the discussion$/i })
        .focus(); // Focus activates the Submit button and mini toolbar below a comment textbox

      cy.get('@main')
        .findByRole('button', { name: /^Use a response template$/i })
        .click();

      cy.get('@main')
        .findByRole('button', { name: /^Insert$/i })
        .click();

      cy.get('@main')
        .findByRole('textbox', { name: /^Add a comment to the discussion$/i })
        .should('have.value', 'This is a test canned response');

      cy.get('@main')
        .findByRole('button', { name: /^Submit$/i })
        .click();

      // Comment was saved so the new comment textbox should be empty.
      cy.get('@main')
        .findByRole('textbox', { name: /^Add a comment to the discussion$/i })
        .should('have.value', '');

      cy.get('@main').findByRole('heading', { name: 'Discussion (1)' });
    });
  });
});
