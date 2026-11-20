const DEFAULT_LOCALE = 'en';
let translations = {};
let lastRawTranslations = null;
let payloadLocale = null;

function mergeTranslations(target, source) {
  Object.keys(source).forEach((key) => {
    const sourceVal = source[key];
    const targetVal = target[key];
    if (
      sourceVal &&
      typeof sourceVal === 'object' &&
      !Array.isArray(sourceVal) &&
      targetVal &&
      typeof targetVal === 'object' &&
      !Array.isArray(targetVal)
    ) {
      mergeTranslations(targetVal, sourceVal);
    } else {
      target[key] = sourceVal; // eslint-disable-line no-param-reassign
    }
  });
  return target;
}

function loadTranslations() {
  const translationsDiv = document.getElementById('i18n-translations');
  const rawTranslations = translationsDiv?.dataset?.translations;
  if (rawTranslations && rawTranslations !== lastRawTranslations) {
    lastRawTranslations = rawTranslations;
    mergeTranslations(translations, JSON.parse(rawTranslations));
  }
  payloadLocale = translationsDiv?.dataset?.locale || null;
}

loadTranslations();

const initialLocale =
  payloadLocale || document.body?.dataset?.locale || DEFAULT_LOCALE;

function lookupPath(root, pathSegments) {
  let current = root;
  for (let i = 0; i < pathSegments.length; i += 1) {
    if (current == null || typeof current !== 'object') {
      return undefined;
    }
    current = current[pathSegments[i]];
  }
  return current;
}

export function locale(term, params = {}) {
  loadTranslations();

  const activeLocale =
    payloadLocale ||
    document.body?.dataset?.locale ||
    initialLocale ||
    DEFAULT_LOCALE;
  const pathSegments = String(term).split('.');

  let value = lookupPath(translations[activeLocale], pathSegments);
  if (value === undefined && activeLocale !== DEFAULT_LOCALE) {
    value = lookupPath(translations[DEFAULT_LOCALE], pathSegments);
  }

  if (
    value != null &&
    typeof value === 'object' &&
    Object.prototype.hasOwnProperty.call(params, 'count')
  ) {
    if (params.count === 0 && 'zero' in value) {
      value = value.zero;
    } else if (params.count === 1 && 'one' in value) {
      value = value.one;
    } else {
      value = value.other;
    }
  }

  if (typeof value !== 'string') {
    return `[missing "${activeLocale}.${term}" translation]`;
  }

  return value.replace(/%\{(\w+)\}/g, (match, key) =>
    Object.prototype.hasOwnProperty.call(params, key) ? params[key] : match,
  );
}
