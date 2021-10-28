describe('Post Editor', () => {
  describe('v1 Editor', () => {
    beforeEach(() => {
      cy.testSetup();
      cy.fixture('users/articleEditorV1User.json').as('user');

      cy.get('@user').then((user) => {
        cy.loginAndVisit(user, '/new');
      });
    });

    it('should preview blank content of a post', () => {
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

    it('should show the accessibility suggestions notice', () => {
      cy.findByRole('form', { name: /^Edit post$/i }).as('articleForm');

      // Add a heading level one which should cause an accessibility lint error
      cy.get('@articleForm')
        .findByLabelText('Post Content')
        .clear()
        .type('# Heading level one');

      cy.get('@articleForm')
        .findByRole('button', { name: /^Preview$/i })
        .click();

      cy.findByRole('heading', {
        name: 'Improve the accessibility of your post',
      }).should('exist');
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
        cy.loginAndVisit(user, '/new');
      });
    });

    it('should preview blank content of a post', () => {
      cy.findByRole('form', { name: /^Edit post$/i }).as('articleForm');

      cy.get('@articleForm')
        .findByRole('button', { name: /^Preview$/i })
        .as('previewButton');
      cy.get('@previewButton').should('not.have.attr', 'aria-current');

      cy.get('@previewButton').click();
      cy.get('@previewButton').should('have.attr', 'aria-current', 'page');

      cy.findByTestId('error-message').should('not.exist');
    });

    it('should preview content of a post with a gist embed', () => {
      cy.findByRole('form', { name: /^Edit post$/i }).as('articleForm');

      cy.get('@articleForm')
        .findByLabelText('Post Content')
        .type(
          'Here is a gist: {% gist https://gist.github.com/CristinaSolana/1885435.js %}',
          { parseSpecialCharSequences: false },
        );

      cy.get('@articleForm')
        .findByRole('button', { name: /^Preview$/i })
        .as('previewButton');
      cy.get('@previewButton').should('not.have.attr', 'aria-current');

      cy.get('@previewButton').click();
      cy.get('@previewButton').should('have.attr', 'aria-current', 'page');

      cy.findByTestId('error-message').should('not.exist');
      cy.get('#gist1885435').should('be.visible');
      cy.findByRole('link', { name: 'view raw' });
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

    it('should show the accessibility suggestions notice', () => {
      cy.findByRole('form', { name: /^Edit post$/i }).as('articleForm');

      // Add a heading level one which should cause an accessibility lint error
      cy.get('@articleForm')
        .findByLabelText('Post Content')
        .clear()
        .type('# Heading level one');

      cy.get('@articleForm')
        .findByRole('button', { name: /^Preview$/i })
        .click();

      cy.findByRole('heading', {
        name: 'Improve the accessibility of your post',
      }).should('exist');
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

  describe('Accessibility suggestions', () => {
    beforeEach(() => {
      cy.testSetup();
      cy.fixture('users/articleEditorV2User.json').as('user');

      cy.get('@user').then((user) => {
        cy.loginAndVisit(user, '/new');
      });
    });

    it("shouldn't show accessibility suggestions if an error notice is present", () => {
      const postTextWithError = '# Heading level one';

      cy.findByRole('form', { name: /^Edit post$/i }).as('articleForm');

      // Cause an error by having a non tag liquid tag without a tag name in the post body.
      cy.get('@articleForm')
        .findByLabelText('Post Content')
        .clear()
        .type(`${postTextWithError}\n{%tag %}`, {
          parseSpecialCharSequences: false,
        });

      cy.get('@articleForm')
        .findByRole('button', { name: /^Preview$/i })
        .click();

      cy.findByTestId('error-message').should('be.visible');

      cy.findByRole('heading', {
        name: 'Improve the accessibility of your post',
      }).should('not.exist');
    });

    it('should show a maximum of 3 accessibility suggestions', () => {
      const postTextWithFourErrors =
        '# Heading level 1\n![](http://imagewithoutalt.png)\n![Image description](http://imagewithdefaultalt.png)\n#### Heading level 4';
      cy.findByRole('form', { name: /^Edit post$/i }).as('articleForm');

      cy.get('@articleForm')
        .findByLabelText('Post Content')
        .clear()
        .type(postTextWithFourErrors);

      cy.get('@articleForm')
        .findByRole('button', { name: /^Preview$/i })
        .click();

      // Check the notice has appeared
      cy.findByRole('heading', {
        name: 'Improve the accessibility of your post',
      });

      // Check each expected description has appeared
      cy.findByText(
        "Consider replacing the 'Image description' in square brackets at ![Image description](http://imagewithdefaultalt.png) with a description of the image",
      );
      cy.findByText(
        'Consider adding an image description in the square brackets at ![](http://imagewithoutalt.png)',
      );
      cy.findByText(
        'Consider changing "# Heading level 1" to a level two heading by using "##"',
      );

      // Check details links are shown for 3 errors
      cy.findAllByRole('link', {
        name: 'Learn more about accessible images',
      }).should('have.length', 2);
      cy.findAllByRole('link', {
        name: 'Learn more about accessible headings',
      }).should('have.length', 1);
    });

    it('should display image suggestions over heading suggestions', () => {
      const textWithThreeImageErrors =
        '![](http://imageerror1.png)\n![Image description](http://imageerror2.png)\n![Image description](http://imageerror3.png)';
      const textWithHeadingErrors = '# Heading level 1\n #### Heading level 4';

      cy.findByRole('form', { name: /^Edit post$/i }).as('articleForm');

      cy.get('@articleForm')
        .findByLabelText('Post Content')
        .clear()
        .type(`${textWithHeadingErrors}\n${textWithThreeImageErrors}`);

      cy.get('@articleForm')
        .findByRole('button', { name: /^Preview$/i })
        .click();

      // Verify the image suggestions are the only ones shown
      cy.findByRole('link', {
        name: 'Learn more about accessible headings',
      }).should('not.exist');
      cy.findAllByRole('link', {
        name: 'Learn more about accessible images',
      }).should('have.length', 3);
    });

    it('should show a suggestion for level one headings', () => {
      cy.findByRole('form', { name: /^Edit post$/i }).as('articleForm');

      cy.get('@articleForm')
        .findByLabelText('Post Content')
        .clear()
        .type('# Level one heading');

      cy.get('@articleForm')
        .findByRole('button', { name: /^Preview$/i })
        .click();

      cy.findByText(
        'Consider changing "# Level one heading" to a level two heading by using "##"',
      );

      cy.findByRole('link', {
        name: 'Learn more about accessible headings',
      }).should('have.attr', 'href', '/p/editor_guide#accessible-headings');
    });

    it('should show a suggestion when heading level increases by more than one', () => {
      cy.findByRole('form', { name: /^Edit post$/i }).as('articleForm');

      cy.get('@articleForm')
        .findByLabelText('Post Content')
        .clear()
        .type('## Level two heading\n#### Level four heading');

      cy.get('@articleForm')
        .findByRole('button', { name: /^Preview$/i })
        .click();

      cy.findByText(
        'Consider changing the heading "#### Level four heading" to a level 3 heading by using "###"',
      );

      cy.findByRole('link', {
        name: 'Learn more about accessible headings',
      }).should('have.attr', 'href', '/p/editor_guide#accessible-headings');
    });

    it('should show a suggestion for empty alt text on images', () => {
      cy.findByRole('form', { name: /^Edit post$/i }).as('articleForm');

      cy.get('@articleForm')
        .findByLabelText('Post Content')
        .clear()
        .type('![](http://image1.png)');

      cy.get('@articleForm')
        .findByRole('button', { name: /^Preview$/i })
        .click();

      cy.findByText(
        'Consider adding an image description in the square brackets at ![](http://image1.png)',
      );

      cy.findByRole('link', {
        name: 'Learn more about accessible images',
      }).should('have.attr', 'href', '/p/editor_guide#alt-text-for-images');
    });

    it('should show a suggestion for default alt text on images', () => {
      cy.findByRole('form', { name: /^Edit post$/i }).as('articleForm');

      cy.get('@articleForm')
        .findByLabelText('Post Content')
        .clear()
        .type(
          '![Image description](http://image1.png)\n![Image description](http://image2.png)',
        );

      cy.get('@articleForm')
        .findByRole('button', { name: /^Preview$/i })
        .click();

      cy.findByText(
        "Consider replacing the 'Image description' in square brackets at ![Image description](http://image1.png) with a description of the image",
      );

      cy.findByText(
        "Consider replacing the 'Image description' in square brackets at ![Image description](http://image2.png) with a description of the image",
      );

      cy.findAllByRole('link', {
        name: 'Learn more about accessible images',
      }).should('have.length', 2);
      cy.findAllByRole('link', {
        name: 'Learn more about accessible images',
      })
        .first()
        .should('have.attr', 'href', '/p/editor_guide#alt-text-for-images');
    });

    it('should show the correct suggestion for alt text when other text exists on the same line', () => {
      cy.findByRole('form', { name: /^Edit post$/i }).as('articleForm');

      cy.get('@articleForm')
        .findByLabelText('Post Content')
        .clear()
        .type(
          'Some text ![Image description](http://image1.png) Some more text',
        );

      cy.get('@articleForm')
        .findByRole('button', { name: /^Preview$/i })
        .click();

      cy.findByText(
        "Consider replacing the 'Image description' in square brackets at ![Image description](http://image1.png) with a description of the image",
      );
    });
  });
});
