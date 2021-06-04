describe('Comment on articles', () => {
  // In these tests we have purposefully avoided the use of aliasing (https://docs.cypress.io/guides/core-concepts/variables-and-aliases#Aliases)
  // Making use of aliases is generally best practice, but due to the implementation of the autocomplete component (switching between two different textareas) it can cause flakiness in these particular tests

  const getCommentCombobox = () =>
    cy.findByRole('combobox', {
      name: /^Add a comment to the discussion$/i,
    });

  const getCommentDropdown = () => cy.findByRole('listbox');

  // Check for the wrapper's test ID first, to make sure we don't grab a reference to a textarea that is being replaced
  const getCommentPlainTextBox = () =>
    cy.findByRole('textbox', {
      name: /^Add a comment to the discussion$/i,
    });

  const getReplyPlainCommentBox = () =>
    cy.findByRole('textbox', {
      name: /^Reply to a comment\.\.\.$/,
    });

  const getReplyCombobox = () =>
    cy.findByRole('combobox', { name: /^Reply to a comment\.\.\.$/ });

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
    it('should comment on an article with user mention autocomplete suggesting max 6 users', () => {
      cy.intercept(
        { method: 'GET', url: '/search/usernames?username=se' },
        { fixture: 'search/usernames.json' },
      );

      cy.findByRole('main').within(() => {
        cy.findByRole('textbox', {
          name: /^Add a comment to the discussion$/i,
        }).click();

        // Make sure the comment box has been substituted with the autocomplete one
        cy.findByTestId('autocomplete-wrapper');

        // Get a handle to the newly substituted textbox
        getCommentPlainTextBox();
        getCommentPlainTextBox().type('Some text @s');

        // Verify the combobox has appeared
        getCommentCombobox();
        getCommentCombobox().should('have.focus');
      });

      cy.findByText('Type to search for a user').should('exist');
      getCommentCombobox().type('e');
      getCommentDropdown().should('exist');

      const expectedUsernameMatches = [
        /@search_user_1/,
        /@search_user_2/,
        /@search_user_2/,
        /@search_user_3/,
        /@search_user_4/,
        /@search_user_5/,
        /@search_user_6/,
      ];

      expectedUsernameMatches.forEach((name) =>
        cy.findByRole('option', { name }).should('exist'),
      );
      cy.findByRole('option', { name: /@search_user_7/ }).should('not.exist');
      cy.findByRole('option', { name: /@search_user_3/ }).focus();
      cy.findByRole('option', { name: /@search_user_3/ }).click();

      getCommentDropdown().should('not.exist');

      cy.findByRole('main').within(() => {
        getCommentPlainTextBox().should('have.focus');
        getCommentPlainTextBox().should(
          'have.value',
          'Some text @search_user_3 ',
        );
      });
    });

    it('should select a mention autocomplete suggestion by keyboard', () => {
      cy.intercept(
        { method: 'GET', url: '/search/usernames?username=se' },
        { fixture: 'search/usernames.json' },
      );

      cy.findByRole('main').within(() => {
        cy.findByRole('textbox', {
          name: /^Add a comment to the discussion$/i,
        }).click();

        // Make sure the comment box has been substituted with the autocomplete one
        cy.findByTestId('autocomplete-wrapper');

        // Get a handle to the newly substituted textbox
        getCommentPlainTextBox();
        getCommentPlainTextBox().type('Some text @s');

        // Verify the combobox has appeared
        getCommentCombobox();
        getCommentCombobox().should('have.focus');
        getCommentCombobox().type('e');
      });

      cy.findByRole('option', { name: /@search_user_1/ });

      cy.findByRole('main').within(() => {
        getCommentCombobox().type('{downarrow}{enter}');

        getCommentPlainTextBox().should('have.focus');
        getCommentPlainTextBox().should(
          'have.value',
          'Some text @search_user_1 ',
        );
      });
    });

    it('should accept entered comment text without user mention if no autocomplete suggestions', () => {
      cy.intercept(
        { method: 'GET', url: '/search/usernames?username=us' },
        { fixture: 'search/emptyUsernamesSearch.json' },
      );

      cy.findByRole('main').within(() => {
        cy.findByRole('textbox', {
          name: /^Add a comment to the discussion$/i,
        }).click();

        // Make sure the comment box has been substituted with the autocomplete one
        cy.findByTestId('autocomplete-wrapper');

        // Get a handle to the newly substituted textbox
        getCommentPlainTextBox();
        getCommentPlainTextBox().type('Some text @u');

        // Verify the combobox has appeared
        getCommentCombobox();
        getCommentCombobox().should('have.focus');

        getCommentCombobox().type('s');
      });

      cy.findByText('No results found').should('exist');
      getCommentCombobox().type(' ');

      cy.findByText('No results found').should('not.exist');
      getCommentPlainTextBox().should('have.focus');
      getCommentPlainTextBox().should('have.value', 'Some text @us ');
    });

    it('should stop showing mention autocomplete suggestions on text delete', () => {
      cy.intercept(
        { method: 'GET', url: '/search/usernames?username=se' },
        { fixture: 'search/usernames.json' },
      );

      cy.findByRole('main').within(() => {
        cy.findByRole('textbox', {
          name: /^Add a comment to the discussion$/i,
        }).click();

        // Make sure the comment box has been substituted with the autocomplete one
        cy.findByTestId('autocomplete-wrapper');

        // Get a handle to the newly substituted textbox
        getCommentPlainTextBox();
        getCommentPlainTextBox().type('Some text @s');

        // Verify the combobox has appeared
        getCommentCombobox();

        getCommentCombobox().should('have.focus');
        getCommentCombobox().type('e');
      });

      getCommentDropdown();
      cy.findByRole('option', { name: /@search_user_1/ }).should('exist');

      getCommentCombobox().type('{backspace}{backspace}{backspace}');
      cy.findByRole('option', { name: /@search_user_1/ }).should('not.exist');
    });

    it('should resume search suggestions when user types after deleting', () => {
      cy.intercept(
        { method: 'GET', url: '/search/usernames?username=se' },
        { fixture: 'search/usernames.json' },
      );

      cy.findByRole('main').within(() => {
        cy.findByRole('textbox', {
          name: /^Add a comment to the discussion$/i,
        }).click();

        // Make sure the comment box has been substituted with the autocomplete one
        cy.findByTestId('autocomplete-wrapper');

        // Get a handle to the newly substituted textbox
        getCommentPlainTextBox();
        getCommentPlainTextBox().type('Some text @se');

        // Verify the combobox has appeared
        getCommentCombobox();

        getCommentCombobox().should('have.focus');
        getCommentCombobox().type('{backspace}{backspace}');
      });

      cy.findByRole('option', { name: /@search_user_1/ }).should('not.exist');

      getCommentCombobox().type('se');
      cy.findByRole('option', { name: /@search_user_1/ }).should('exist');
    });

    it('should close the autocomplete suggestions on Escape press', () => {
      cy.intercept(
        { method: 'GET', url: '/search/usernames?username=se' },
        { fixture: 'search/usernames.json' },
      );

      cy.findByRole('main').within(() => {
        cy.findByRole('textbox', {
          name: /^Add a comment to the discussion$/i,
        }).click();

        // Make sure the comment box has been substituted with the autocomplete one
        cy.findByTestId('autocomplete-wrapper');

        // Get a handle to the newly substituted textbox
        getCommentPlainTextBox();
        getCommentPlainTextBox().type('Some text @s');

        // Verify the combobox has appeared
        getCommentCombobox();

        getCommentCombobox().type('e');
      });

      getCommentDropdown();
      cy.findByRole('option', { name: /@search_user_1/ }).should('exist');

      getCommentCombobox().type('{Esc}');
      cy.findByRole('option', { name: /@search_user_1/ }).should('not.exist');
    });

    it('should close the autocomplete suggestions and exit combobox on click outside', () => {
      cy.intercept(
        { method: 'GET', url: '/search/usernames?username=se' },
        { fixture: 'search/usernames.json' },
      );

      cy.findByRole('main').within(() => {
        cy.findByRole('textbox', {
          name: /^Add a comment to the discussion$/i,
        }).click();

        // Make sure the comment box has been substituted with the autocomplete one
        cy.findByTestId('autocomplete-wrapper');

        // Get a handle to the newly substituted textbox
        getCommentPlainTextBox();
        getCommentPlainTextBox().type('Some text @s');

        // Verify the combobox has appeared
        getCommentCombobox();

        getCommentCombobox().type('e');
      });

      getCommentDropdown();
      cy.findByRole('option', { name: /@search_user_1/ }).should('be.visible');

      // Click away from the dropdown
      getCommentCombobox().click({ position: 'right' });
      cy.findByRole('option', { name: /@search_user_1/ }).should('not.exist');

      // Check the combobox has exited and we are returned to the plainTextArea
      getCommentPlainTextBox().should('have.focus');
    });

    it('should exit combobox when blurred and refocused', () => {
      cy.intercept(
        { method: 'GET', url: '/search/usernames?username=s' },
        { fixture: 'search/usernames.json' },
      );

      cy.findByRole('main').within(() => {
        cy.findByRole('textbox', {
          name: /^Add a comment to the discussion$/i,
        }).click();

        // Make sure the comment box has been substituted with the autocomplete one
        cy.findByTestId('autocomplete-wrapper');

        // Get a handle to the newly substituted textbox
        getCommentPlainTextBox();
        getCommentPlainTextBox().type('Some text @s');

        // Verify the combobox has appeared
        getCommentCombobox();

        // Blur the currently active textarea, and check that the blur results in the plainTextArea being restored
        getCommentCombobox().blur();
        getCommentCombobox().should('not.exist');
        getCommentPlainTextBox().should('exist');
      });
    });

    it('should reply to a comment with user mention autocomplete', () => {
      cy.intercept(
        { method: 'GET', url: '/search/usernames?username=se' },
        { fixture: 'search/usernames.json' },
      );

      cy.findByRole('main').within(() => {
        cy.findByRole('textbox', {
          name: /^Add a comment to the discussion$/i,
        }).click();

        // Make sure the comment box has been substituted with the autocomplete one
        cy.findByTestId('autocomplete-wrapper');

        // Create a comment to test replying to
        getCommentPlainTextBox().type('first comment');
        cy.findByRole('button', { name: /^Submit$/i }).click();

        cy.findByRole('link', { name: /^Reply$/i }).click();

        // Make sure we wait until the reply comment box has been substituted with the autocomplete one
        cy.findAllByTestId('autocomplete-wrapper').should('have.length', 2);

        getReplyPlainCommentBox().click();
        getReplyPlainCommentBox().type('Some text @s');

        // Verify the combobox has appeared
        getReplyCombobox();
        getReplyCombobox().type('e');
      });

      // Pick an item from the dropdown
      getCommentDropdown();
      cy.findByRole('option', { name: /@search_user_1/ }).focus();
      cy.findByRole('option', { name: /@search_user_1/ }).click();

      getReplyPlainCommentBox().should(
        'have.value',
        'Some text @search_user_1 ',
      );
    });

    it('should pre-populate a comment field when editing', () => {
      cy.findByRole('main').within(() => {
        cy.findByRole('textbox', {
          name: /^Add a comment to the discussion$/i,
        }).click();

        // Make sure the comment box has been substituted with the autocomplete one
        cy.findByTestId('autocomplete-wrapper');

        // Get a handle to the newly substituted textbox
        getCommentPlainTextBox();
        getCommentPlainTextBox().type('first comment');

        cy.findByRole('button', { name: /Submit/ }).click();
        cy.findByRole('link', { name: /Reply/ });
      });

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
    cy.findByRole('main').within(() => {
      cy.findByRole('heading', { name: 'Discussion (0)' });

      cy.findByRole('textbox', { name: /^Add a comment to the discussion$/i })
        .focus() // Focus activates the Submit button and mini toolbar below a comment textbox
        .type('this is a comment');

      cy.findByRole('textbox', {
        name: /^Add a comment to the discussion$/i,
      }).should('have.value', 'this is a comment');

      cy.findByRole('button', { name: /^Submit$/i }).click();

      // Comment was saved so the new comment textbox should be empty.
      cy.findByRole('textbox', {
        name: /^Add a comment to the discussion$/i,
      }).should('have.value', '');

      cy.findByText(/^this is a comment$/i);
      cy.findByRole('heading', { name: 'Discussion (1)' });
    });
  });

  it('should add a comment from a response template', () => {
    cy.createResponseTemplate({
      title: 'Test Canned Response',
      content: 'This is a test canned response',
    }).then((_response) => {
      cy.findByRole('main').within(() => {
        cy.findByRole('heading', { name: 'Discussion (0)' });

        cy.findByRole('textbox', {
          name: /^Add a comment to the discussion$/i,
        }).focus(); // Focus activates the Submit button and mini toolbar below a comment textbox

        cy.findByRole('button', { name: /^Use a response template$/i }).click();

        cy.findByRole('button', { name: /^Insert$/i }).click();

        cy.findByRole('textbox', {
          name: /^Add a comment to the discussion$/i,
        }).should('have.value', 'This is a test canned response');

        cy.findByRole('button', { name: /^Submit$/i }).click();

        // Comment was saved so the new comment textbox should be empty.
        cy.findByRole('textbox', {
          name: /^Add a comment to the discussion$/i,
        }).should('have.value', '');

        cy.findByRole('heading', { name: 'Discussion (1)' });
      });
    });
  });

  it('should show rate limit modal', () => {
    cy.intercept('POST', '/comments', { statusCode: 429, body: {} });
    cy.findByRole('main').within(() => {
      cy.findByRole('textbox', { name: /^Add a comment to the discussion$/i })
        .focus() // Focus activates the Submit button and mini toolbar below a comment textbox
        .type('this is a comment');

      cy.findByRole('button', { name: /^Submit$/i }).click();
    });

    cy.findByTestId('modal-container').within(() => {
      cy.findByRole('button', { name: /Close/ }).should('have.focus');
      cy.findByRole('heading', { name: 'Wait a moment...' }).should('exist');
      cy.findByText(
        'Since you recently made a comment, you’ll need to wait a moment before making another comment.',
      );
      cy.findByRole('button', { name: 'Got it' }).click();
    });

    cy.findByTestId('modal-container').should('not.exist');
    cy.findByRole('button', { name: /^Submit$/i }).should('have.focus');
  });

  it('should show error modal', () => {
    cy.intercept('POST', '/comments', {
      statusCode: 500,
      body: { error: 'Test error' },
    });
    cy.findByRole('main').within(() => {
      cy.findByRole('textbox', { name: /^Add a comment to the discussion$/i })
        .focus() // Focus activates the Submit button and mini toolbar below a comment textbox
        .type('this is a comment');

      cy.findByRole('button', { name: /^Submit$/i }).click();
    });

    cy.findByTestId('modal-container').within(() => {
      cy.findByRole('button', { name: /Close/ }).should('have.focus');
      cy.findByRole('heading', { name: 'Error posting comment' }).should(
        'exist',
      );
      cy.findByText(
        'Your comment could not be posted due to an error: Test error',
      );
      cy.findByRole('button', { name: 'OK' }).click();
    });

    cy.findByTestId('modal-container').should('not.exist');
    cy.findByRole('button', { name: /^Submit$/i }).should('have.focus');
  });

  it('should provide a dropdown of options', () => {
    cy.findByRole('main').within(() => {
      // Add a comment
      cy.findByRole('textbox', { name: /^Add a comment to the discussion$/i })
        .focus() // Focus activates the Submit button and mini toolbar below a comment textbox
        .type('this is a comment');

      cy.findByRole('button', { name: /^Submit$/i }).click();

      // Open and inspect the dropdown menu
      cy.findByRole('button', { name: /^Toggle dropdown menu$/i }).as(
        'dropdownButton',
      );
      cy.get('@dropdownButton').click();
      cy.findByRole('link', {
        name: /^Copy link to Article Editor v1 User's comment$/i,
      }).should('have.focus');
      cy.findByRole('link', {
        name: /^Go to Article Editor v1 User's comment settings$/i,
      });
      cy.findByRole('link', {
        name: "Report Article Editor v1 User's comment as abusive or violating our code of conduct and/or terms and conditions",
      });
      cy.findByRole('link', { name: /^Edit this comment$/i });
      cy.findByRole('link', { name: /^Delete this comment$/i });

      // Verify that the dropdown closes again
      cy.get('@dropdownButton').click();
      cy.findByRole('link', {
        name: /^Copy link to Article Editor v1 User's comment$/i,
      }).should('not.exist');
    });
  });

  it('should close the comment dropdown on Escape press, returning focus', () => {
    // Add a comment
    cy.findByRole('textbox', { name: /^Add a comment to the discussion$/i })
      .focus() // Focus activates the Submit button and mini toolbar below a comment textbox
      .type('this is a comment');
    cy.findByRole('button', { name: /^Submit$/i }).click();

    cy.findByRole('button', { name: /^Toggle dropdown menu$/i }).as(
      'dropdownButton',
    );
    cy.get('@dropdownButton').click();
    cy.findByRole('link', {
      name: /^Copy link to Article Editor v1 User's comment$/i,
    }).should('have.focus');

    cy.get('body').type('{esc}');
    cy.findByRole('link', {
      name: /^Copy link to Article Editor v1 User's comment$/i,
    }).should('not.exist');
    cy.get('@dropdownButton').should('have.focus');
  });

  it('should show dropdown options on comment index page', () => {
    cy.findByRole('textbox', { name: /^Add a comment to the discussion$/i })
      .focus() // Focus activates the Submit button and mini toolbar below a comment textbox
      .type('this is a comment');
    cy.findByRole('button', { name: /^Submit$/i }).click();

    cy.findByRole('button', { name: /^Toggle dropdown menu$/i }).click();
    cy.findByRole('link', { name: /^Edit this comment$/i }).click();

    // In the comment index page, click submit without making changes
    cy.findByRole('button', { name: /^Submit$/i }).click();

    // Check the dropdown has initialized
    cy.findByRole('button', { name: /^Toggle dropdown menu$/i }).click();
    cy.findByRole('link', { name: /^Edit this comment$/i });
    // Close the dropdown again
    cy.findByRole('button', { name: /^Toggle dropdown menu$/i }).click();
    cy.findByRole('link', { name: /^Edit this comment$/i }).should('not.exist');
  });
});
