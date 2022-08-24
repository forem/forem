describe('Search pagination', () => {
  beforeEach(() => {
    cy.testSetup();
  });

  describe('Has more than 30 result articles', () => {
    beforeEach(() => {
      cy.fixture('users/articleEditorV1User.json').as('user');

      cy.get('@user').then((user) => {
        cy.loginUser(user).then(() => {
          //create more than 30 articles
          for (let i = 1; i <= 33; i++) {
            cy.createArticle({
              title: `Test Article ${i}`,
              published: true,
            });
          }
        });
      });
    });

    it('should show paginator indicator', function () {
      cy.visit('/search?q=test&filters=class_name:Article');

      cy.findByRole('heading', { name: 'Test article' }).should('exist');

      cy.findByRole('group', { name: 'Pagination group of buttons' }).should(
        'be.visible',
      );
      cy.findByRole('group', { name: 'Pagination group of buttons' }).within(
        () => {
          cy.findByRole('button', { name: 'Page 1' }).should('exist');
          cy.findByRole('button', { name: 'Page 1' }).should(
            'have.class',
            'crayons-btn',
          );
          cy.findByRole('button', { name: 'Page 2' }).should('exist');
        },
      );
    });

    it('should go to the next page with url param', function () {
      cy.visit('/search?q=test&filters=class_name:Article&page=2');

      cy.findByRole('heading', { name: 'Test Article 33' }).should('exist');

      cy.findByRole('group', { name: 'Pagination group of buttons' }).should(
        'be.visible',
      );
      cy.findByRole('group', { name: 'Pagination group of buttons' }).within(
        () => {
          cy.findByRole('button', { name: 'Page 1' }).should('exist');
          cy.findByRole('button', { name: 'Page 2' }).should('exist');
          cy.findByRole('button', { name: 'Page 2' }).should(
            'have.class',
            'crayons-btn',
          );
        },
      );
    });

    it('should navigate with the pagination numbers widgets', function () {
      cy.visit('/search?q=test&filters=class_name:Article');

      cy.findByRole('group', { name: 'Pagination group of buttons' }).within(
        () => {
          cy.findByRole('button', { name: 'Page 2' }).click();
        },
      );

      cy.findByRole('heading', { name: 'Test Article 33' }).should('exist');

      cy.findByRole('group', { name: 'Pagination group of buttons' }).within(
        () => {
          cy.findByRole('button', { name: 'Page 1' }).click();
        },
      );

      cy.findByRole('heading', { name: 'Test article' }).should('exist');
    });

    it('should navigate with the pagination rows widgets', function () {
      cy.visit('/search?q=test&filters=class_name:Article');

      cy.findByRole('group', { name: 'Pagination group of buttons' }).within(
        () => {
          cy.findByRole('button', { name: 'Next Page' }).click();
        },
      );

      cy.findByRole('heading', { name: 'Test Article 33' }).should('exist');

      cy.findByRole('group', { name: 'Pagination group of buttons' }).within(
        () => {
          cy.findByRole('button', { name: 'Previous Page' }).click();
        },
      );

      cy.findByRole('heading', { name: 'Test article' }).should('exist');
    });
  });

  it('should no show paginator indicator when articles result less than 30', function () {
    cy.visit('/search?q=test&filters=class_name:Article');

    cy.findByRole('heading', { name: 'Test article' }).should('exist');

    cy.findByRole('group', { name: 'Pagination group of buttons' }).should(
      'not.exist',
    );
  });

  it('should no show paginator indicator when articles are empty', function () {
    cy.visit('/search?q=empty%20search&filters=class_name:Article');

    cy.findByRole('main').within(() => {
      cy.contains('No results match that query').should('be.visible');
    });

    cy.findByRole('group', { name: 'Pagination group of buttons' }).should(
      'not.exist',
    );
  });
});
