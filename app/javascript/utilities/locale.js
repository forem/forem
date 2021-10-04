import i18next from 'i18next';
import { initReactI18next } from 'react-i18next';

const {locale} = document.body.dataset;
const dictionary = require(`../i18n/${locale}.json`);

i18next
  .use(initReactI18next)
  .init({
    lng: locale,
    resources: {
      [locale]: {
        translation: dictionary,
      },
    },
    interpolation: { prefix: '%{', suffix: '}' },
    react: {
      transKeepBasicHtmlNodesFor: ['br', 'strong', 'b', 'em', 'i', 'p']
    }
  });

export { i18next, locale };
