import I18n from "i18n-js"
const translationsDiv = document.getElementById('i18n-translations')
if (translationsDiv) {
  I18n.translations = JSON.parse(translationsDiv.dataset.translations);
}
I18n.defaultLocale = 'en';
I18n.locale = document.body.dataset.locale;
export function locale(term) {
  return I18n.t(term);
}