describe('Comment on articles', () => {
  // TestId ensures we get a reference to the substituted text area with autocomplete features
  const getEnhancedCommentTextBox = () =>
    cy
      .findByTestId('autocomplete-wrapper')
      .findByRole('textbox', /name: ^Add a comment to the discussion$/i);

  const verifyComboboxMode = () =>
    cy
      .findByTestId('autocomplete-wrapper')
      .findByRole('combobox', /name: ^Add a comment to the discussion$/i);

  const verifyNotInComboboxMode = () =>
    cy
      .findByTestId('autocomplete-wrapper')
      .findByRole('combobox', /name: ^Add a comment to the discussion$/i)
      .should('not.exist');

  const getCommentDropdown = () => cy.findByRole('listbox');

  const getReplyCommentBox = () =>
    cy.findByRole('textbox', {
      name: /^Reply to a comment\.\.\.$/,
    });

  const verifyReplyComentBoxIsComboboxMode = () =>
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
          cy.visitAndWaitForUserSideEffects(response.body.current_state_path);
        });
      });
    });
  });

  describe('Comments using mention autocomplete', () => {
    it('should comment on an article with user mention autocomplete suggesting max 6 users', () => {
      cy.intercept(
        { method: 'GET', url: '/search/usernames*' },
        { fixture: 'search/usernames.json' },
      );

      cy.findByRole('main').within(() => {
        cy.findByRole('textbox', {
          name: /^Add a comment to the discussion$/i,
        }).click();

        // Get a handle to the newly substituted textbox
        getEnhancedCommentTextBox().as('commentTextArea');
        cy.get('@commentTextArea').type('Some text @s');
        verifyComboboxMode();
      });

      cy.findAllByText('Type to search for a user').should('exist');
      cy.get('@commentTextArea').type('e');
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
      cy.findByRole('option', { name: /@search_user_3/ }).click();

      getCommentDropdown().should('not.exist');
      verifyNotInComboboxMode();

      cy.get('@commentTextArea').should(
        'have.value',
        'Some text @search_user_3 ',
      );
    });

    it('should select a mention autocomplete suggestion by keyboard', () => {
      cy.intercept(
        { method: 'GET', url: '/search/usernames*' },
        { fixture: 'search/usernames.json' },
      );

      cy.findByRole('main').within(() => {
        cy.findByRole('textbox', {
          name: /^Add a comment to the discussion$/i,
        }).click();

        // Make sure the comment box has been substituted with the autocomplete one
        getEnhancedCommentTextBox().as('commentTextArea');

        cy.get('@commentTextArea').type('Some text @s');
        verifyComboboxMode();
        cy.get('@commentTextArea').type('e');
      });

      cy.findByRole('option', { name: /@search_user_1/ });

      cy.findByRole('main').within(() => {
        cy.get('@commentTextArea').type('{downarrow}{enter}');
        verifyNotInComboboxMode();
        cy.get('@commentTextArea').should(
          'have.value',
          'Some text @search_user_1 ',
        );
      });
    });

    it('should accept entered comment text without user mention if no autocomplete suggestions', () => {
      cy.intercept(
        { method: 'GET', url: '/search/usernames*' },
        { fixture: 'search/emptyUsernamesSearch.json' },
      );

      cy.findByRole('main').within(() => {
        cy.findByRole('textbox', {
          name: /^Add a comment to the discussion$/i,
        }).click();

        // Make sure the comment box has been substituted with the autocomplete one
        getEnhancedCommentTextBox().as('commentTextArea');

        cy.get('@commentTextArea').type('Some text @u');
        verifyComboboxMode();
        cy.get('@commentTextArea').type('s');
      });

      cy.findByText('No results found').should('exist');
      cy.get('@commentTextArea').type(' ');

      cy.findByText('No results found').should('not.exist');
      verifyNotInComboboxMode();
      cy.get('@commentTextArea').should('have.value', 'Some text @us ');
    });

    it('should stop showing mention autocomplete suggestions on text delete', () => {
      cy.intercept(
        { method: 'GET', url: '/search/usernames*' },
        { fixture: 'search/usernames.json' },
      );

      cy.findByRole('main').within(() => {
        cy.findByRole('textbox', {
          name: /^Add a comment to the discussion$/i,
        }).click();

        // Make sure the comment box has been substituted with the autocomplete one
        getEnhancedCommentTextBox().as('commentTextArea');

        cy.get('@commentTextArea').type('Some text @s');
        verifyComboboxMode();
        cy.get('@commentTextArea').type('e');
      });

      getCommentDropdown();
      cy.findByRole('option', { name: /@search_user_1/ }).should('exist');

      cy.get('@commentTextArea').type('{backspace}{backspace}{backspace}');
      cy.findByRole('option', { name: /@search_user_1/ }).should('not.exist');
    });

    it('should resume search suggestions when user types after deleting', () => {
      cy.intercept(
        { method: 'GET', url: '/search/usernames*' },
        { fixture: 'search/usernames.json' },
      );

      cy.findByRole('main').within(() => {
        cy.findByRole('textbox', {
          name: /^Add a comment to the discussion$/i,
        }).click();

        // Make sure the comment box has been substituted with the autocomplete one
        getEnhancedCommentTextBox().as('commentTextArea');

        cy.get('@commentTextArea').type('Some text @se');
        verifyComboboxMode();
        cy.get('@commentTextArea').type('{backspace}{backspace}');
      });

      cy.findByRole('option', { name: /@search_user_1/ }).should('not.exist');

      cy.get('@commentTextArea').type('se');
      cy.findByRole('option', { name: /@search_user_1/ }).should('exist');
    });

    it('should close the autocomplete suggestions on Escape press', () => {
      cy.intercept(
        { method: 'GET', url: '/search/usernames*' },
        { fixture: 'search/usernames.json' },
      );

      cy.findByRole('main').within(() => {
        cy.findByRole('textbox', {
          name: /^Add a comment to the discussion$/i,
        }).click();

        // Make sure the comment box has been substituted with the autocomplete one
        getEnhancedCommentTextBox().as('commentTextArea');
        cy.get('@commentTextArea').type('Some text @se');
      });

      getCommentDropdown();
      cy.findByRole('option', { name: /@search_user_1/ }).should('exist');

      cy.get('@commentTextArea').type('{Esc}');
      cy.findByRole('option', { name: /@search_user_1/ }).should('not.exist');
    });

    // TODO: fix
    it('should close the autocomplete suggestions and exit combobox on click elsewhere in text area', () => {
      cy.intercept(
        { method: 'GET', url: '/search/usernames*' },
        { fixture: 'search/usernames.json' },
      );

      cy.findByRole('main').within(() => {
        cy.findByRole('textbox', {
          name: /^Add a comment to the discussion$/i,
        }).click();

        // Make sure the comment box has been substituted with the autocomplete one
        getEnhancedCommentTextBox().as('commentTextArea');
        cy.get('@commentTextArea').type('Some text @se');
        verifyComboboxMode();
      });

      getCommentDropdown();
      cy.findByRole('option', { name: /@search_user_1/ }).should('be.visible');

      // Click away from the dropdown
      cy.get('@commentTextArea').click({ position: 'right' });
      cy.findByRole('option', { name: /@search_user_1/ }).should('not.exist');
    });

    it('should exit combobox when blurred and refocused', () => {
      cy.intercept(
        { method: 'GET', url: '/search/usernames*' },
        { fixture: 'search/usernames.json' },
      );

      cy.findByRole('main').within(() => {
        cy.findByRole('textbox', {
          name: /^Add a comment to the discussion$/i,
        }).click();

        // Make sure the comment box has been substituted with the autocomplete one
        getEnhancedCommentTextBox().as('commentTextArea');

        cy.get('@commentTextArea').type('Some text @s');
        verifyComboboxMode();

        // Blur the textarea, and check that the blur results in exiting combobox mode
        cy.get('@commentTextArea').blur();
        verifyNotInComboboxMode();
      });
    });

    it('should reply to a comment with user mention autocomplete', () => {
      cy.intercept(
        { method: 'GET', url: '/search/usernames*' },
        { fixture: 'search/usernames.json' },
      );

      cy.findByRole('main').within(() => {
        cy.findByRole('textbox', {
          name: /^Add a comment to the discussion$/i,
        }).click();

        // Create a comment to test replying to
        getEnhancedCommentTextBox().type('first comment');
        cy.findByRole('button', { name: /^Submit$/i }).click();

        cy.findByRole('link', { name: /^Reply$/i }).click();

        // Make sure we wait until the reply comment box has been substituted with the autocomplete one
        cy.findAllByTestId('autocomplete-wrapper').should('have.length', 2);

        getReplyCommentBox().as('replyCommentBox');
        cy.get('@replyCommentBox').type('Some text @se');
        verifyReplyComentBoxIsComboboxMode();
      });

      // Pick an item from the dropdown
      getCommentDropdown();
      cy.findByRole('option', { name: /@search_user_1/ }).click();

      cy.get('@replyCommentBox').should(
        'have.value',
        'Some text @search_user_1 ',
      );
    });

    it('should pre-populate a comment field when editing', () => {
      cy.findByRole('main').within(() => {
        cy.findByRole('textbox', {
          name: /^Add a comment to the discussion$/i,
        }).click();

        getEnhancedCommentTextBox().type('first comment');

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
      cy.findByRole('heading', { name: 'Top comments (0)' });

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
      cy.findByRole('heading', { name: 'Top comments (1)' });

      // Check that the profile preview card is there and can be displayed
      cy.findByTestId('comments-container').within(() => {
        // Wait for the dropdown to initialize
        cy.get('button[id^=comment-profile-preview-trigger][data-initialized]');

        cy.findByRole('button', {
          name: 'Article Editor v1 User profile details',
        }).click();

        cy.findByTestId('profile-preview-card').within(() => {
          cy.findByRole('button', { name: 'Edit profile' });
          cy.findByRole('link', { name: 'Article Editor v1 User' });
        });
      });
    });
  });

  it('should add a comment from a response template', () => {
    cy.createResponseTemplate({
      title: 'Test Canned Response',
      content: 'This is a test canned response',
    }).then((_response) => {
      cy.findByRole('main').within(() => {
        cy.findByRole('heading', { name: 'Top comments (0)' });

        cy.findByRole('textbox', {
          name: /^Add a comment to the discussion$/i,
        }).focus(); // Focus activates the Submit button and mini toolbar below a comment textbox

        cy.findByRole('button', { name: 'More options' }).click();
        cy.findByRole('menuitem', { name: 'Show templates' }).click();

        cy.findByRole('button', { name: /^Insert$/i }).click();

        cy.findByRole('textbox', {
          name: /^Add a comment to the discussion$/i,
        }).should('have.value', 'This is a test canned response');

        cy.findByRole('button', { name: /^Submit$/i }).click();

        // Comment was saved so the new comment textbox should be empty.
        cy.findByRole('textbox', {
          name: /^Add a comment to the discussion$/i,
        }).should('have.value', '');

        cy.findByRole('heading', { name: 'Top comments (1)' });
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
        'Since you recently posted a comment, you’ll need to wait a moment before posting another comment.',
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

  it('server error that return empty body should show error modal', () => {
    cy.intercept('POST', '/comments', {
      statusCode: 503,
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
      cy.findByText('Your comment could not be posted due to a server error');
      cy.findByRole('button', { name: 'OK' }).click();
    });

    cy.findByTestId('modal-container').should('not.exist');
    cy.findByRole('button', { name: /^Submit$/i }).should('have.focus');
  });

  it('should add a comment with a gist embed', () => {
    cy.findByRole('main').within(() => {
      cy.findByRole('textbox', {
        name: /^Add a comment to the discussion$/i,
      }).type(
        'Here is a gist: {% gist https://gist.github.com/CristinaSolana/1885435.js %}',
        { parseSpecialCharSequences: false },
      );

      cy.findByRole('button', { name: /^Submit$/i }).click();
    });
    cy.get('#gist1885435').should('be.visible');
    cy.findByRole('link', { name: 'view raw' });
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

  it('should toggle aria-pressed button', () => {
    cy.visitAndWaitForUserSideEffects('/admin_mcadmin/test-article-slug');

    // SVG should exists with Like comment: as title
    cy.findByRole('img', { name: 'Like comment:' });

    cy.findByTestId('comments-container').within(() => {
      cy.findByRole('button', { name: /^like$/i })
        .as('likeButton')
        .should('exist')
        .and('have.attr', 'aria-pressed', 'false')
        .and('not.have.class', 'reacted');

      cy.get('@likeButton').within(() => {
        cy.get('span.reactions-count').should('have.text', '0');
        cy.get('span.reactions-label').should(($span) => {
          expect($span.text().trim()).equal('');
        });
      });

      // React on comment
      cy.get('@likeButton').click();

      // Text should change and react class should be added along with aria-pressed
      cy.get('@likeButton')
        .and('have.attr', 'aria-pressed', 'true')
        .and('have.class', 'reacted');
      cy.get('@likeButton').within(() => {
        cy.get('span.reactions-count').should('have.text', '1');
        cy.get('span.reactions-label').should(($span) => {
          expect($span.text().trim()).equal('like');
        });
      });

      // Unreact on comment
      cy.get('@likeButton').click();

      // Text should change and react class should be added along with aria-pressed
      cy.get('@likeButton')
        .and('have.attr', 'aria-pressed', 'false')
        .and('not.have.class', 'reacted');
      cy.get('@likeButton').within(() => {
        cy.get('span.reactions-count').should('have.text', '0');
        cy.get('span.reactions-label').should(($span) => {
          expect($span.text().trim()).equal('');
        });
      });
    });
  });

  it('should enhance the textarea with a markdown toolbar', () => {
    cy.findByRole('main').within(() => {
      cy.findByRole('heading', { name: 'Top comments (0)' });

      cy.findByRole('textbox', {
        name: /^Add a comment to the discussion$/i,
      })
        .as('textArea')
        .focus();
      cy.findByRole('toolbar').as('toolbar');

      cy.get('@toolbar').findByRole('button', { name: 'Bold' }).click();
      cy.get('@textArea').should('have.value', '****').should('have.focus');
    });
  });
});
