describe('Hovering on article publish date', () => {
  const checkFullDateOnHover = (selector, { locale = '' }) => {
    cy.get(selector).should((elements) => {
      elements.each((_, element) => {
        const date = new Date(element.getAttribute('datetime'));
        const formattedDate = new Intl.DateTimeFormat(locale, {
          weekday: 'long',
          month: 'long',
          day: 'numeric',
        }).format(date);

        expect(element.getAttribute('title')).contains(formattedDate);
      });
    });
  };

  beforeEach(() => {
    cy.testSetup();
  });

  it('shows full date on the logged-out home page', () => {
    for (const locale of ['en-US', 'fr-FR', 'es-ES']) {
      cy.visitWithLocale('/', locale);
      checkFullDateOnHover('.crayons-story__meta time', { locale });
    }
  });

  it('shows full date on the tagged articles page', () => {
    for (const locale of ['en-US', 'fr-FR', 'es-ES']) {
      cy.visitWithLocale('/t/tag1', locale);
      checkFullDateOnHover('.crayons-story__meta time', { locale });
    }
  });

  it('shows full date on an article page', () => {
    for (const locale of ['en-US', 'fr-FR', 'es-ES']) {
      cy.visitWithLocale('/admin_mcadmin/test-article-slug', locale);
      checkFullDateOnHover('.crayons-story__meta time', { locale });
    }
  });

  it('shows full date on user and organisation profile pages', () => {
    for (const locale of ['en-US', 'fr-FR', 'es-ES']) {
      cy.visitWithLocale('/admin_mcadmin', locale);
      checkFullDateOnHover('.crayons-story__meta time', { locale });

      cy.findByRole('link', { name: 'Bachmanity' }).click();
      checkFullDateOnHover('.crayons-story__meta time', { locale });
    }
  });

  context('on a series list page', () => {
    beforeEach(() => {
      cy.fixture('users/seriesUser.json').as('user');
      cy.get('@user')
        .then((user) => cy.loginUser(user))
        .then(() =>
          cy.createArticle({
            title: 'Second Test Post',
            content: 'Some more content so the series switcher shows up',
            series: 'seriestest',
            published: true,
          }),
        )
        .then((response) => {
          cy.visitAndWaitForUserSideEffects(response.body.current_state_path);
        });
    });

    it('shows full date', () => {
      cy.findByRole('link', { name: /^seriestest/ }).click();
      cy.findByRole('heading', { name: "seriestest Series' Articles" });

      cy.url().then((url) => {
        for (const locale of ['en-US', 'fr-FR', 'es-ES']) {
          cy.visitWithLocale(url, locale);
          checkFullDateOnHover('.crayons-story__meta time', { locale });
        }
      });
    });
  });
});
