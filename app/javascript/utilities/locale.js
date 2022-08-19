import { I18n } from 'i18n-js';

const i18n = new I18n();

const translationsDiv = document.getElementById('i18n-translations');
if (translationsDiv) {
  const translations = JSON.parse(translationsDiv.dataset.translations);
  i18n.store(translations);
}
i18n.defaultLocale = 'en';
const { locale: userLocale } = document.body.dataset;
if (userLocale) {
  i18n.locale = userLocale;
}
export function locale(term) {
  return i18n.t(term);
}
