describe('Post reactions drawer', () => {
  const findHiddenButton = (label, { as = 'nothing' } = {}) => {
    cy.findByRole('button', { name: label, hidden: true })
      .as(as)
      .should('not.be.visible');
  };

  const findAllReactionButtons = () => {
    findHiddenButton('Like', { as: 'heartReaction' });
    findHiddenButton('Unicorn', { as: 'unicornReaction' });
    findHiddenButton('Exploding Head', { as: 'headReaction' });
    findHiddenButton('Raised Hands', { as: 'handsReaction' });
    findHiddenButton('Fire', { as: 'fireReaction' });

    return [
      '@heartReaction',
      '@unicornReaction',
      '@headReaction',
      '@handsReaction',
      '@fireReaction',
    ];
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

  context('on desktop', () => {
    beforeEach(() => {
      cy.viewport('macbook-16');
    });

    it('should open and close on hover', () => {
      const reactions = findAllReactionButtons();

      cy.findByRole('button', { name: 'reaction-drawer-trigger' })
        .as('reactionDrawerButton')
        .trigger('mouseover');

      for (const reaction of reactions) {
        cy.get(reaction).should('be.visible');
      }

      cy.get('@reactionDrawerButton').trigger('mouseout');

      for (const reaction of reactions) {
        cy.get(reaction).should('not.be.visible');
      }
    });
  });

  context('on mobile', () => {
    beforeEach(() => {
      cy.url().then((url) => {
        cy.visitOnMobile(url);
      });
    });

    it('should open on long press and close on a tap outside it', () => {
      const reactions = findAllReactionButtons();

      // Dismiss deep link banner
      cy.findByRole('button', { name: 'Dismiss banner' }).click();

      cy.findByRole('button', { name: 'reaction-drawer-trigger' })
        .as('reactionDrawerButton')
        .trigger('touchstart');

      for (const reaction of reactions) {
        cy.get(reaction).should('be.visible');
      }

      cy.get('@reactionDrawerButton').trigger('touchend');

      for (const reaction of reactions) {
        cy.get(reaction).should('be.visible');
      }
    });
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

  context('when reacting fails', () => {
    // For UX reasons the UI shows a "successful" reaction before the actual request
    // to create the reaction returns from the server
    it('should revert the reaction if the user is offline', () => {
      cy.intercept('POST', '/reactions', { forceNetworkError: true }).as(
        'reactRequest',
      );

      cy.findByRole('button', { name: 'reaction-drawer-trigger' })
        .as('reactionDrawerButton')
        .trigger('mouseover');
      cy.findByRole('button', { name: 'Unicorn' }).as('unicornReaction');

      checkReactions('@unicornReaction', { count: 0 });
      checkReactions('@reactionDrawerButton', { count: 0 });

      cy.get('@unicornReaction').click();
      cy.wait('@reactRequest');
      checkReactions('@unicornReaction', { count: 0 });
      checkReactions('@reactionDrawerButton', { count: 0 });
    });

    it('should also notify the user', () => {
      cy.intercept('POST', '/reactions', { statusCode: 404 }).as(
        'reactRequest',
      );

      cy.findByRole('button', { name: 'reaction-drawer-trigger' })
        .as('reactionDrawerButton')
        .trigger('mouseover');
      cy.findByRole('button', { name: 'Unicorn' }).as('unicornReaction');

      checkReactions('@unicornReaction', { count: 0 });
      checkReactions('@reactionDrawerButton', { count: 0 });

      cy.get('@unicornReaction').click();
      cy.wait('@reactRequest');

      cy.findByRole('heading', { name: 'Error updating reaction' }).should(
        'be.visible',
      );
      checkReactions('@unicornReaction', { count: 0 });
      checkReactions('@reactionDrawerButton', { count: 0 });
    });
  });
});
