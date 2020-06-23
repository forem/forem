const time_options = {
  hour: 'numeric',
  minute: 'numeric',
};

const date_options = {
  month: 'short',
  day: 'numeric',
};

export const formatDate = (timestamp, currentLocale) => {
  const dateToday = new Date();
  const articlePublished = new Date(timestamp);
  const locale = currentLocale || 'default';

  if (dateToday.toDateString() === articlePublished.toDateString()) {
    return articlePublished.toLocaleString(locale, time_options);
  }
  return articlePublished.toLocaleString(locale, date_options);
};
