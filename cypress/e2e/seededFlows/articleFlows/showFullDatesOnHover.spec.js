describe('Publish date on article pages', () => {
  const visitWithLocale = (url, locale) => {
    cy.visit(url, {
      onBeforeLoad: (window) => {
        // Override locales
        Object.defineProperty(window.navigator, 'language', { value: locale });
        Object.defineProperty(window.navigator, 'languages', {
          value: [locale],
        });
      },
    });
  };

  const haveFullDateOnHover = ({ localizedIn = '' }) => {
    return (elements) => {
      elements.each((_, element) => {
        const date = new Date(element.getAttribute('datetime'));
        const formattedDate = new Intl.DateTimeFormat(localizedIn, {
          weekday: 'long',
          month: 'long',
          day: 'numeric',
        }).format(date);

        expect(element.getAttribute('title')).contains(formattedDate);
      });
    };
  };

  beforeEach(() => {
    cy.testSetup();
    cy.fixture('users/articleEditorV2User.json').as('user');

    cy.get('@user')
      .then((user) => cy.loginUser(user))
      .then(() =>
        cy.createArticle({
          title: 'First Post',
          content: 'First kittens post',
          series: 'Kittens',
          published: true,
        }),
      )
      .then(() =>
        cy.createArticle({
          title: 'Second Post',
          content: 'Second kittens post',
          series: 'Kittens',
          published: true,
        }),
      )
      .then((response) => {
        cy.visitAndWaitForUserSideEffects(response.body.current_state_path);
      });
  });

  it('shows in full on hover', () => {
    cy.url().then((url) => {
      for (const locale in ['en-US', 'fr-FR', 'es-ES']) {
        visitWithLocale(url, locale);

        cy.get('.crayons-article__header__meta').within(() => {
          cy.get('time').should(haveFullDateOnHover({ localizedIn: locale }));
        });
      }
    });
  });
});
