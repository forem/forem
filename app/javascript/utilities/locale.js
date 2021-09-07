import { I18n } from '../i18n-js/index.js.erb'

I18n.defaultLocale = 'en';
I18n.locale = document.body.dataset.locale;
export function locale(term) {
  let translatedTerm = term; 
  if (I18n) {
    translatedTerm =  I18n.t(term);
  }
  return translatedTerm;
}