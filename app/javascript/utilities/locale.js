import { I18n } from 'i18n-js';

const i18n = new I18n();

i18n.translationsLoaded = false;

i18n.ensureTranslationsAvailable = function() {
  if (this.translationsLoaded) {
    return;
  }

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

  i18n.translationsLoaded = true;
}

export function locale(term, params = {}) {
  i18n.ensureTranslationsAvailable();
  return i18n.t(term, params);
}
