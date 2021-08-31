/* eslint-disable no-undef */
I18n.defaultLocale = 'en';
I18n.locale = document.body.dataset.locale;
export function locale(term) {
  return I18n.t(term);
}