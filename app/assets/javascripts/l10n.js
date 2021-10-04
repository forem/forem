//= require lib/i18next

const locale = document.documentElement.lang;

(async () => {
  let dictionary = await (
    await fetch(`/javascripts/i18n/${locale}.json`)
  ).json();

  i18next.init({
    lng: locale,
    resources: {
      [locale]: {
        translation: dictionary,
      },
    },
    interpolation: { prefix: '%{', suffix: '}' },
  });
})();
