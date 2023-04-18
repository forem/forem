describe('Post reactions drawer', () => {
  const findHiddenButton = (label, { as = 'nothing' } = {}) => {
    cy.findByRole('button', { name: label, hidden: true })
      .as(as)
      .should('not.be.visible');
  };

  const checkReactions = (variable, { count = 0 } = {}) => {
    cy.get(variable).within(() => {
      cy.get('.crayons-reaction__count').should('have.text', `${count}`);
    });
  };

  beforeEach(() => {
    cy.testSetup();
    cy.fixture('users/articleEditorV2User.json').as('user');

    cy.get('@user').then((user) => {
      cy.loginUser(user).then(() => {
        cy.createArticle({
          title: 'Test Article',
          tags: ['python'],
          content: `This is an article about ball pythons.`,
          published: true,
        }).then((response) => {
          cy.visitAndWaitForUserSideEffects(response.body.current_state_path);
        });
      });
    });
  });

  it('should open and close on hover', () => {
    findHiddenButton('Like', { as: 'heartReaction' });
    findHiddenButton('Unicorn', { as: 'unicornReaction' });
    findHiddenButton('Exploding Head', { as: 'headReaction' });
    findHiddenButton('Raised Hands', { as: 'handsReaction' });
    findHiddenButton('Fire', { as: 'fireReaction' });

    const reactions = [
      '@heartReaction',
      '@unicornReaction',
      '@headReaction',
      '@handsReaction',
      '@fireReaction',
    ];

    cy.findByRole('button', { name: 'reaction-drawer-trigger' }).trigger(
      'mouseover',
    );

    for (const reaction of reactions) {
      cy.get(reaction).should('be.visible');
    }

    cy.findByRole('button', { name: 'reaction-drawer-trigger' }).trigger(
      'mouseout',
    );

    for (const reaction of reactions) {
      cy.get(reaction).should('not.be.visible');
    }
  });

  it('should act as a like button when clicked', () => {
    cy.intercept('POST', '/reactions').as('reactRequest');

    findHiddenButton('Like', { as: 'heartReaction' });
    checkReactions('@heartReaction', { count: 0 });

    cy.findByRole('button', { name: 'reaction-drawer-trigger' }).as(
      'reactionDrawerButton',
    );
    checkReactions('@reactionDrawerButton', { count: 0 });

    cy.get('@reactionDrawerButton').click();
    cy.wait('@reactRequest');
    checkReactions('@heartReaction', { count: 1 });
    checkReactions('@reactionDrawerButton', { count: 1 });

    cy.get('@reactionDrawerButton').click();
    cy.wait('@reactRequest');
    checkReactions('@heartReaction', { count: 0 });
    checkReactions('@reactionDrawerButton', { count: 0 });
  });

  it('should contain working reaction buttons', () => {
    cy.intercept('POST', '/reactions').as('reactRequest');

    cy.findByRole('button', { name: 'reaction-drawer-trigger' })
      .as('reactionDrawerButton')
      .trigger('mouseover');
    checkReactions('@reactionDrawerButton', { count: 0 });

    cy.findByRole('button', { name: 'Like' }).as('heartReaction').click();
    cy.wait('@reactRequest');
    checkReactions('@heartReaction', { count: 1 });
    checkReactions('@reactionDrawerButton', { count: 1 });

    cy.findByRole('button', { name: 'Unicorn' }).as('unicornReaction').click();
    cy.wait('@reactRequest');
    checkReactions('@unicornReaction', { count: 1 });
    checkReactions('@reactionDrawerButton', { count: 2 });

    cy.findByRole('button', { name: 'Exploding Head' })
      .as('headReaction')
      .click();
    cy.wait('@reactRequest');
    checkReactions('@headReaction', { count: 1 });
    checkReactions('@reactionDrawerButton', { count: 3 });

    cy.findByRole('button', { name: 'Raised Hands' })
      .as('handsReaction')
      .click();
    cy.wait('@reactRequest');
    checkReactions('@handsReaction', { count: 1 });
    checkReactions('@reactionDrawerButton', { count: 4 });

    cy.findByRole('button', { name: 'Fire' }).as('fireReaction').click();
    cy.wait('@reactRequest');
    checkReactions('@fireReaction', { count: 1 });
    checkReactions('@reactionDrawerButton', { count: 5 });

    const reactions = [
      '@heartReaction',
      '@unicornReaction',
      '@headReaction',
      '@handsReaction',
      '@fireReaction',
    ];
    let totalCount = 5;

    // Test un-reacting
    for (const reaction of reactions) {
      cy.get(reaction).click();
      cy.wait('@reactRequest');

      totalCount -= 1;
      checkReactions(reaction, { count: 0 });
      checkReactions('@reactionDrawerButton', { count: totalCount });
    }
  });
});
