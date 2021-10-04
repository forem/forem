//= require lib/i18next

const locale = document.documentElement.lang;

// we need a sync XHR to ensure the locale file loaded
let dicRequest = new XMLHttpRequest();
dicRequest.open('GET', `/javascripts/i18n/${locale}.json`, false);
dicRequest.send();

let dictionary = JSON.parse(
  dicRequest.status === 200 ? dicRequest.responseText : '{}',
);

i18next.init({
  lng: locale,
  resources: {
    [locale]: {
      translation: dictionary,
    },
  },
  interpolation: { prefix: '%{', suffix: '}' },
});
