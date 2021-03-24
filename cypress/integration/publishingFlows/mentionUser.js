describe('Article Editor', () => {
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
        { method: 'GET', url: '/search/usernames' },
        { fixture: 'search/usernames.json' },
      );

      cy.findByRole('combobox').as('articleForm');

      cy.get('@articleForm').type('Post content @s');
      cy.findByText('Type to search for a user').should('exist');
      cy.get('@articleForm').type('earch');

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
      cy.findByDisplayValue('Post content @search_user_3').should('exist');
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
        { method: 'GET', url: '/search/usernames' },
        { fixture: 'search/usernames.json' },
      );

      cy.findByRole('combobox').as('articleForm');

      cy.get('@articleForm').type('Post content @s');
      cy.findByText('Type to search for a user').should('exist');
      cy.get('@articleForm').type('earch');

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
      cy.findByDisplayValue('Post content @search_user_3').should('exist');
    });
  });
});
