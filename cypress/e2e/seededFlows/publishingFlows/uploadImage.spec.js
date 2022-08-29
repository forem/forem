describe('Upload image', () => {
  describe('Article V1 Editor', () => {
    beforeEach(() => {
      cy.testSetup();

      cy.fixture('users/articleEditorV1User.json').as('user');

      cy.get('@user').then((user) => {
        cy.loginAndVisit(user, '/new');
      });
    });

    it('Uploads an image in the editor and copies the markdown', () => {
      cy.findByRole('form', { name: 'Edit post' }).within(() => {
        cy.findByLabelText(/Upload image/).attachFile(
          '/images/admin-image.png',
        );
      });

      // Confirm the UI has updated to show the uploaded state
      cy.findByRole('button', {
        name: 'Copy markdown for image',
      }).click();

      cy.findByText('Copied!').should('exist');

      cy.window()
        .its('navigator.clipboard')
        .invoke('readText')
        .should('contain', '![Image description](');
    });
  });

  describe('Article V2 Editor', () => {
    beforeEach(() => {
      cy.testSetup();

      cy.fixture('users/articleEditorV2User.json').as('user');

      cy.get('@user').then((user) => {
        cy.loginAndVisit(user, '/new');
      });
    });

    it('successfully uploads an image and inserts image markdown', () => {
      cy.findByLabelText('Post Content').clear();

      cy.findByLabelText(/Upload image/, { selector: 'input' }).attachFile(
        '/images/admin-image.png',
      );

      cy.findByLabelText('Post Content')
        .invoke('val')
        .should('match', /!\[Uploading image\]/);

      cy.findByLabelText('Post Content')
        .invoke('val')
        .should('match', /!\[Image description\]/);
    });

    it('cancels an in-progress image upload and displays an error', () => {
      cy.intercept('/image_uploads', { delay: 2000 });

      cy.findByLabelText('Post Content').as('editorBody');
      cy.get('@editorBody').clear();

      cy.findByLabelText(/Upload image/, { selector: 'input' }).attachFile(
        '/images/admin-image.png',
      );

      // Check the uploading placeholder is shown
      cy.get('@editorBody')
        .invoke('val')
        .should('match', /\n!\[Uploading image\]/);

      // Cancel the upload and check the placeholder is removed
      cy.findByRole('button', { name: 'Cancel image upload' }).click();
      cy.get('@editorBody').should('have.value', '\n');

      // Mouseover on snackbar ensures it remains readable for test duration
      cy.findByTestId('snackbar')
        .trigger('mouseover')
        .findByRole('alert')
        .should('have.text', 'The user aborted a request.');
    });

    it('shows an error for failed image upload', () => {
      cy.intercept('/image_uploads', {
        statusCode: 500,
        body: {
          error: 'Error message',
        },
      });

      cy.findByLabelText('Post Content').as('editorBody');
      cy.get('@editorBody').clear();

      cy.findByLabelText(/Upload image/, { selector: 'input' }).attachFile(
        '/images/admin-image.png',
      );

      // Check placeholder is removed from text area
      cy.get('@editorBody').should('have.value', '\n');

      // Mouseover on snackbar ensures it remains readable for test duration
      cy.findByTestId('snackbar')
        .trigger('mouseover')
        .findByRole('alert')
        .should('have.text', 'Error message');
    });

    it('maintains writing position when image is uploaded', () => {
      cy.intercept('/image_uploads', { delay: 2000 });

      cy.findByLabelText('Post Content').as('editorBody');
      // Type some text and place the cursor between one & two
      cy.get('@editorBody')
        .clear()
        .type('one two{leftarrow}{leftarrow}{leftarrow}');

      cy.findByLabelText(/Upload image/, { selector: 'button' }).click();
      cy.findByLabelText(/Upload image/, { selector: 'input' }).attachFile(
        '/images/admin-image.png',
      );

      // Check that when we continue typing after selecting an image, my cursor is after the placeholder text, which was inserted at my cursor position
      cy.get('@editorBody').should('have.focus').type(' more text ');
      cy.get('@editorBody').should(
        'have.value',
        'one \n![Uploading image](...) more text two',
      );
    });

    it('Uploads a cover image in the editor', () => {
      cy.findByRole('form', { name: 'Edit post' }).within(() => {
        cy.findByLabelText(/Add a cover image.*/).attachFile(
          '/images/admin-image.png',
        );

        // Confirm the UI has updated to show the uploaded state
        cy.findByLabelText(/Change.*/).should('exist');
        cy.findByRole('button', { name: 'Remove' }).should('exist');
      });
    });
  });
});
