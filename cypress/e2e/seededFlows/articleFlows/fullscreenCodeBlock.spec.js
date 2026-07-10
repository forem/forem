describe('Fullscreen code block exit control', () => {
  beforeEach(() => {
    cy.testSetup();
    cy.fixture('users/articleEditorV1User.json').as('user');

    cy.get('@user').then((user) => {
      cy.loginUser(user).then(() => {
        cy.createArticle({
          title: 'Fullscreen code article',
          tags: ['beginner'],
          content: ['```ruby', 'def hello', '  puts "hi"', 'end', '```'].join(
            '\n',
          ),
          published: true,
        }).then((response) => {
          cy.visitAndWaitForUserSideEffects(response.body.current_state_path);
        });
      });
    });
  });

  // The enter control lives in a hover-revealed panel on the article page, so we
  // force the click. Everything the tests actually assert is the EXIT experience.
  const enterFullscreen = () =>
    cy
      .get('main .js-code-highlight .js-fullscreen-code-action')
      .first()
      .click({ force: true });

  const overlay = () => cy.get('.fullscreen-code.is-open');
  const exitControl = () =>
    cy.get('.fullscreen-code.is-open .highlight-action--fullscreen-off');

  it('opens on a single click and stays open (does not collapse)', () => {
    // The old boolean state could invert a click, opening then instantly closing
    // the overlay. A single click must leave it open with its cloned code intact.
    enterFullscreen();

    overlay().should('exist');
    overlay().find('.js-code-highlight').should('exist');
    overlay().find('pre.highlight').should('contain.text', 'puts');
  });

  it('reveals an exit control that is visible without hover', () => {
    // Regression for #23535: the panel only un-hid on `:hover`, so the exit
    // affordance was invisible on touch/non-hover devices.
    enterFullscreen();

    exitControl().should('be.visible');
  });

  it('places the exit control above the header so it is not occluded', () => {
    // The overlay sits under the fixed header by default (z-index 500 vs 10000),
    // burying the exit control. A real (non-forced) click only succeeds if the
    // control is both visible AND on top — Cypress fails the click if it is
    // covered by another element, so this is the z-index regression test.
    enterFullscreen();
    overlay().should('exist');

    exitControl().click();
    cy.get('.fullscreen-code.is-open').should('not.exist');
  });

  it('exits fullscreen on the Escape key', () => {
    enterFullscreen();
    overlay().should('exist');

    cy.get('body').trigger('keyup', { key: 'Escape' });
    cy.get('.fullscreen-code.is-open').should('not.exist');
  });

  it('re-opens after exiting, with state always in sync', () => {
    // Exit then re-enter: a stale flag used to desync here and no-op the reopen.
    enterFullscreen();
    exitControl().click();
    cy.get('.fullscreen-code.is-open').should('not.exist');

    enterFullscreen();
    overlay().should('exist');
    exitControl().should('be.visible');
  });

  it('keeps working after a back/forward navigation', () => {
    enterFullscreen();
    overlay().should('exist');

    // A browser back/forward fires popstate while the container may be swapped
    // out. Dispatch it directly so the assertion does not depend on the history
    // stack, while still exercising the same handler the back button triggers.
    cy.window().then((win) => {
      win.dispatchEvent(new PopStateEvent('popstate'));
    });
    cy.get('.fullscreen-code.is-open').should('not.exist');

    // The interrupted session must not leave state stuck: re-enter, and confirm
    // both the exit control and Escape still tear it down.
    enterFullscreen();
    overlay().should('exist');
    exitControl().should('be.visible');

    cy.get('body').trigger('keyup', { key: 'Escape' });
    cy.get('.fullscreen-code.is-open').should('not.exist');
  });
});
