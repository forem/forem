const timeOptions = {
  hour: 'numeric',
  minute: 'numeric',
};

const dateOptions = {
  month: 'short',
  day: 'numeric',
};

const currentLocale = window.navigator.languages
  ? window.navigator.languages[0]
  : window.navigator.userLanguage || window.navigator.language;

export const formatDate = (timestamp) => {
  const dateToday = new Date();
  const articlePublished = new Date(timestamp);

  if (dateToday.toDateString() === articlePublished.toDateString()) {
    return articlePublished.toLocaleString(currentLocale, timeOptions);
  }
  return articlePublished.toLocaleString(currentLocale, dateOptions);
};
