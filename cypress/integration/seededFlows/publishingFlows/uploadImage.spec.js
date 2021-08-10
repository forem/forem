describe('Upload image', () => {
  describe('Article V1 Editor', () => {
    beforeEach(() => {
      cy.testSetup();

      cy.fixture('users/articleEditorV1User.json').as('user');

      cy.get('@user').then((user) => {
        cy.loginAndVisit(user, '/new');
      });
    });

    it('Uploads an image in the editor', () => {
      cy.findByRole('form', { name: 'Edit post' }).within(() => {
        cy.findByLabelText(/Upload image/).attachFile(
          '/images/admin-image.png',
        );
      });

      // Confirm the UI has updated to show the uploaded state
      cy.findByRole('button', {
        name: 'Copy Markdown for imageCopy...',
      }).should('exist');
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

    it('Uploads an image in the editor', () => {
      cy.findByRole('form', { name: 'Edit post' }).within(() => {
        cy.findByLabelText(/Upload image/).attachFile(
          '/images/admin-image.png',
        );
      });

      // Confirm the UI has updated to show the uploaded state
      cy.findByRole('button', {
        name: 'Copy Markdown for imageCopy...',
      }).should('exist');
    });

    it('Uploads a cover image in the editor', () => {
      cy.findByRole('form', { name: 'Edit post' }).within(() => {
        cy.findByLabelText(/Add a cover image/).attachFile(
          '/images/admin-image.png',
        );

        // Confirm the UI has updated to show the uploaded state
        cy.findByLabelText('Change').should('exist');
        cy.findByRole('button', { name: 'Remove' }).should('exist');
      });
    });
  });
});
