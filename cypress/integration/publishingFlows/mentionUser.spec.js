describe('Article Editor (Mention User)', () => {
  describe('v1 Editor', () => {
    beforeEach(() => {
      cy.testSetup();
      cy.fixture('users/articleEditorV1User.json').as('user');

      cy.get('@user').then((user) => {
        cy.loginUser(user).then(() => {
          cy.visit('/new');
        });
      });
    });

    it('should suggest up to 6 users for autocompletion', () => {
      cy.intercept(
        { method: 'GET', url: '/search/usernames?username=se' },
        { fixture: 'search/usernames.json' },
      );

      cy.findByLabelText('Post Content').as('articleForm');
      cy.get('@articleForm').type('Post content @s');

      cy.findByLabelText('Mention user').as('autocompleteForm');
      cy.get('@autocompleteForm').should('have.focus');
      cy.findByText('Type to search for a user').should('exist');

      cy.get('@autocompleteForm').type('e');

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
      cy.get('@articleForm').should('have.focus');

      cy.get('@articleForm')
        .contains('Post content @search_user_3')
        .should('exist');
    });
  });

  describe('v2 Editor', () => {
    beforeEach(() => {
      cy.testSetup();
      cy.fixture('users/articleEditorV2User.json').as('user');

      cy.get('@user').then((user) => {
        cy.loginUser(user).then(() => {
          cy.visit('/new');
        });
      });
    });

    it('should suggest up to 6 users for autocompletion', () => {
      cy.intercept(
        { method: 'GET', url: '/search/usernames?username=se' },
        { fixture: 'search/usernames.json' },
      );

      cy.findByLabelText('Post Content').as('articleForm');
      cy.get('@articleForm').type('Post content @s');

      cy.findByLabelText('Mention user').as('autocompleteForm');
      cy.get('@autocompleteForm').should('have.focus');
      cy.findByText('Type to search for a user').should('exist');

      cy.get('@autocompleteForm').type('e');

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
      cy.get('@articleForm').should('have.focus');

      cy.get('@articleForm').should(
        'have.value',
        'Post content @search_user_3 ',
      );
    });
  });
});
