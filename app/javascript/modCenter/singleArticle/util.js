import { locale } from '@utilities/locale';

const timeOptions = {
  hour: 'numeric',
  minute: 'numeric',
};

const dateOptions = {
  month: 'short',
  day: 'numeric',
};

const currentLocale = locale;

export const formatDate = (timestamp) => {
  const dateToday = new Date();
  const articlePublished = new Date(timestamp);

  if (dateToday.toDateString() === articlePublished.toDateString()) {
    return articlePublished.toLocaleString(currentLocale, timeOptions);
  }
  return articlePublished.toLocaleString(currentLocale, dateOptions);
};
