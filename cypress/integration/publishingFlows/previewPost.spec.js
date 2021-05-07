describe('Post Editor', () => {
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

    it('should preview blank content of an post', () => {
      cy.findByRole('form', { name: /^Edit post$/i }).as('articleForm');

      cy.get('@articleForm')
        .findByRole('button', { name: /^Preview$/i })
        .as('previewButton');

      cy.get('@previewButton').should('not.have.attr', 'aria-current');

      cy.get('@previewButton').click();
      cy.findByTestId('error-message').should('not.exist');
      cy.get('@previewButton').should('have.attr', 'aria-current', 'page');
    });

    it(`should show error if the post content can't be previewed`, () => {
      cy.findByRole('form', { name: /^Edit post$/i }).as('articleForm');

      // Cause an error by having a non tag liquid tag without a tag name in the post body.
      cy.get('@articleForm')
        .findByLabelText('Post Content')
        .type('{%tag %}', { parseSpecialCharSequences: false });

      cy.get('@articleForm')
        .findByRole('button', { name: /^Preview$/i })
        .as('previewButton');

      cy.get('@previewButton').should('not.have.attr', 'aria-current');

      cy.get('@previewButton').click();

      cy.get('@previewButton').should('not.have.attr', 'aria-current');
      cy.findByTestId('error-message').should('be.visible');
    });

    it('should show the Edit tab by default', () => {
      cy.findByRole('form', { name: /^Edit post$/i })
        .findByRole('navigation', {
          name: 'View post modes',
        })
        .within(() => {
          cy.findByRole('button', { name: /^Edit$/i }).should(
            'have.attr',
            'aria-current',
            'page',
          );
          cy.findByRole('button', { name: /^Preview$/i }).should(
            'not.have.attr',
            'aria-current',
          );
        });
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

    it('should preview blank content of an post', () => {
      cy.findByRole('form', { name: /^Edit post$/i }).as('articleForm');

      cy.get('@articleForm')
        .findByRole('button', { name: /^Preview$/i })
        .as('previewButton');
      cy.get('@previewButton').should('not.have.attr', 'aria-current');

      cy.get('@previewButton').click();
      cy.get('@previewButton').should('have.attr', 'aria-current', 'page');

      cy.findByTestId('error-message').should('not.exist');
    });

    it(`should show error if the post content can't be previewed`, () => {
      cy.findByRole('form', { name: /^Edit post$/i }).as('articleForm');

      // Cause an error by having a non tag liquid tag without a tag name in the post body.
      cy.get('@articleForm')
        .findByLabelText('Post Content')
        .type('{%tag %}', { parseSpecialCharSequences: false });

      cy.get('@articleForm')
        .findByRole('button', { name: /^Preview$/i })
        .as('previewButton');

      cy.get('@previewButton').should('not.have.attr', 'aria-current');

      cy.get('@previewButton').click();

      cy.get('@previewButton').should('not.have.attr', 'aria-current');
      cy.findByTestId('error-message').should('be.visible');
    });

    it('should show the Edit tab by default', () => {
      cy.findByRole('form', { name: /^Edit post$/i })
        .findByRole('navigation', {
          name: 'View post modes',
        })
        .within(() => {
          cy.findByRole('button', { name: /^Edit$/i }).should(
            'have.attr',
            'aria-current',
            'page',
          );
          cy.findByRole('button', { name: /^Preview$/i }).should(
            'not.have.attr',
            'aria-current',
          );
        });
    });
  });
});
