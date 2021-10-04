import i18next from 'i18next';

const locale = document.documentElement.lang;
const dictionary = require(`./${locale}.json`);

i18next.init({
  lng: locale,
  resources: {
    [locale]: {
      translation: dictionary,
    },
  },
  interpolation: { prefix: '%{', suffix: '}' },
});

export { i18next };
