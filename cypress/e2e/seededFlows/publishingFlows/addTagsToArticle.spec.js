describe('Add tags to article', () => {
  const exampleTopTags = [
    {
      name: 'tagone',
      bg_color_hex: '#528973',
    },
    {
      name: 'tagtwo',
      short_summary: 'tag two short summary',
      bg_color_hex: '#c74701',
    },
  ];

  const exampleSearchResult = {
    result: [
      {
        name: 'suggestion',
        short_summary: 'suggestion summary',
      },
    ],
  };

  beforeEach(() => {
    cy.testSetup();
    cy.fixture('users/articleEditorV2User.json').as('user');

    cy.get('@user').then((user) => {
      cy.intercept('/tags/suggest', exampleTopTags).as('topTagsRequest');
      cy.loginAndVisit(user, '/new');
      cy.wait('@topTagsRequest');
    });
  });

  afterEach(() => {
    // Tags added to a draft are saved in local storage, which can cause tags to be pre-filled in subsequent tests
    // We move away from the /new page, and clear the storage to ensure tests are isolated from each other
    cy.visit('/404');
    cy.clearLocalStorage();
  });

  it('properly suggests top tags when field is focused', () => {
    cy.intercept('search/tags**', exampleSearchResult);

    // It is possible in slow running tests that the fetched "top tags" will not be available in the autocomplete before the focus event triggered below.
    // Here we retry the focus event until the combobox expands.
    const focusInputAndGetParentCombobox = ($el) =>
      $el.focus().blur().focus().parents('div');

    // Focus the input automatically return 'top tags'
    cy.findByRole('textbox', { name: 'Add up to 4 tags' })
      .pipe(focusInputAndGetParentCombobox)
      .should('have.attr', 'aria-expanded', 'true');
    cy.findByRole('heading', { name: 'Top tags' }).should('exist');
    cy.findByRole('option', { name: '# tagone' }).should('exist');
    cy.findByRole('option', { name: '# tagtwo tag two short summary' }).should(
      'exist',
    );

    // User select first tag option
    // - Check input has 'reset' and still has focus
    // - Check only the unselected top tag is presented
    cy.findByRole('textbox', { name: 'Add up to 4 tags' }).as('input').focus();
    cy.findByRole('option', { name: '# tagone' }).click();
    cy.get('@input').should('have.value', '').should('have.focus');
    cy.findByRole('heading', { name: 'Top tags' }).should('exist');
    cy.findByRole('option', {
      name: '# tagtwo tag two short summary',
    }).should('exist');
    cy.findByRole('option', { name: '# tagone' }).should('not.exist');

    // User searches for a tag
    // - Top tags should not be shown when a search starts
    cy.findByRole('textbox', { name: 'Add up to 4 tags' }).type('a');
    cy.findByRole('heading', { name: 'Top tags' }).should('not.exist');
    cy.findByRole('option', { name: '# suggestion suggestion summary' }).should(
      'exist',
    );

    // displays currently typed text as a suggestion if no suggestions are returned
    // - Top tags should not be shown when a search starts
    cy.intercept('search/tags**', { result: [] });
    cy.findByRole('textbox', { name: 'Add up to 4 tags' }).type('a');

    cy.findByRole('heading', { name: 'Top tags' }).should('not.exist');
    cy.findByRole('option', { name: '# aa' }).should('exist');
  });

  it('selects a tag by clicking, typing a comma or space', () => {
    cy.findByRole('textbox', { name: 'Add up to 4 tags' }).as('input').focus();
    cy.findByRole('option', { name: '# tagone' }).click();
    cy.findByRole('button', { name: 'Edit tagone' }).should('exist');
    cy.findByRole('button', { name: 'Remove tagone' }).should('exist');
    cy.get('@input').type('something,');
    cy.findByRole('button', { name: 'Edit something' }).should('exist');
    cy.findByRole('button', { name: 'Remove something' }).should('exist');
    cy.get('@input').type('another ');
    cy.findByRole('button', { name: 'Edit another' }).should('exist');
    cy.findByRole('button', { name: 'Remove another' }).should('exist');

    // selects currently entered text when input blurs
    cy.get('@input').type('something');
    cy.get('@input').blur();

    cy.findByRole('button', { name: 'Edit something' }).should('exist');
    cy.findByRole('button', { name: 'Remove something' }).should('exist');
  });

  it('edits and deletes a previous selection', () => {
    cy.findByRole('textbox', { name: 'Add up to 4 tags' })
      .as('input')
      .type('something,');

    cy.findByRole('button', { name: 'Edit something' }).click();
    cy.get('@input').should('have.value', 'something').type('else,');
    cy.findByRole('button', { name: 'Edit somethingelse' }).should('exist');

    cy.findByRole('button', { name: 'Remove somethingelse' }).click();

    // Buttons should be removed and top tags should be showing again
    cy.findByRole('button', { name: 'Edit somethingelse' }).should('not.exist');
    cy.findByRole('button', { name: 'Remove somethingelse' }).should(
      'not.exist',
    );
    cy.findByRole('heading', { name: 'Top tags' }).should('exist');
  });

  it('edits a previous tag when backspace typed', () => {
    cy.findByRole('textbox', { name: 'Add up to 4 tags' })
      .as('input')
      .type('something,');

    // Verify tag is selected
    cy.findByRole('button', { name: 'Edit something' }).should('exist');

    // Verify input was cleared on selection, then type a backspace and check we're now editing the tag again
    cy.get('@input').should('have.focus');
    cy.get('@input').should('have.value', '');
    cy.get('@input').type('{backspace}');
    cy.get('@input').should('have.value', 'something');

    // When editing the edit/remove buttons should not be present any more
    cy.findByRole('button', { name: 'Edit something' }).should('not.exist');
    cy.findByRole('button', { name: 'Remove something' }).should('not.exist');
  });

  it('splits an edited value if space or comma are typed', () => {
    cy.findByRole('textbox', { name: 'Add up to 4 tags' })
      .as('input')
      .type('onetwothree,');

    cy.findByRole('button', { name: 'Edit onetwothree' }).click();

    // Check the input is pre-filled with the selection, and move the cursor to before 'three' before entering a comma
    cy.get('@input')
      .should('have.value', 'onetwothree')
      .type('{leftarrow}{leftarrow}{leftarrow}{leftarrow}{leftarrow},');

    // Everything before the comma should have been selected
    cy.findByRole('button', { name: 'Edit onetwo' }).should('exist');
    // And input should still contain everything to the right of the comma
    cy.get('@input').should('have.value', 'three');

    // Repeat, this time using a space
    cy.findByRole('button', { name: 'Edit onetwo' }).click();
    cy.get('@input')
      .should('have.value', 'onetwo')
      .type('{leftarrow}{leftarrow}{leftarrow} ');

    // Everything before the space should have been selected
    cy.findByRole('button', { name: 'Edit one' }).should('exist');
    cy.get('@input').should('have.value', 'two');
  });

  it('shows a message and prevents further selections when the maximum tags (4) have been added', () => {
    cy.findByRole('textbox', { name: 'Add up to 4 tags' })
      .as('input')
      .type('one, two, three, four,');

    cy.get('@input').should('have.focus').should('have.value', '');

    // Top tags should not be shown when max has been reached
    cy.findByRole('heading', { name: 'Top tags' }).should('not.exist');
    cy.findByText('Only 4 selections allowed').should('exist');

    // Disabled state should be communicated to screen reader users
    cy.get('@input').should('have.attr', 'aria-disabled', 'true');

    // Try to select another tag by typing
    cy.get('@input').type('a');
    // Message should still exist
    cy.findByText('Only 4 selections allowed').should('exist');
    // No options should be shown
    cy.findAllByRole('option').should('have.length', 0);

    // Try to select by typing a comma, and check nothing happens
    cy.get('@input').type(',');
    cy.get('@input').should('have.value', 'a');
    cy.findByRole('button', { name: 'Edit a' }).should('not.exist');

    // Try to select by typing a space, and check nothing happens
    cy.get('@input').type(' ');
    cy.get('@input').should('have.value', 'a');
    cy.findByRole('button', { name: 'Edit a' }).should('not.exist');
  });
});
