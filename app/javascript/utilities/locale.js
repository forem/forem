import I18n from "i18n-js"
I18n.translations = JSON.parse(document.getElementById('i18n-translations').dataset.translations);
I18n.defaultLocale = 'en';
I18n.locale = document.body.dataset.locale;
export function locale(term) {
  return I18n.t(term);
}