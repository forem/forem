'use strict';

/* Local date/time utilities */

/*
  Convert string timestamp to local time, using the given locale.

  timestamp should be something like '2019-05-03T16:02:50.908Z'
  locale can be `navigator.language` or a custom locale. defaults to 'default'
  options are `Intl.DateTimeFormat` options

  see <https://developer.mozilla.org//docs/Web/JavaScript/Reference/Global_Objects/DateTimeFormat>
  for more information.
*/
function timestampToLocalDateTime(timestamp, locale, options) {
  if (!timestamp) {
    return '';
  }

  try {
    var time = new Date(timestamp);
    let formattedTime = new Intl.DateTimeFormat(
      locale || 'default',
      options,
    ).format(time);
    return options.year === '2-digit'
      ? formattedTime.replace(', ', " '")
      : formattedTime;
  } catch (e) {
    return '';
  }
}

function addLocalizedDateTimeToElementsTitles(elements, timestampAttribute) {
  for (var i = 0; i < elements.length; i += 1) {
    var element = elements[i];

    // get UTC timestamp set by the server
    var timestamp = element.getAttribute(timestampAttribute || 'datetime');

    if (timestamp) {
      // add a full datetime to the element title, visible on hover.
      // `navigator.language` is used to allow the date to be localized
      // according to the browser's locale
      // see <https://developer.mozilla.org/en-US/docs/Web/API/NavigatorLanguage/language>
      var localDateTime = timestampToLocalDateTimeLong(timestamp);
      element.setAttribute('title', localDateTime);
    }
  }
}

function localizeTimeElements(elements, timeOptions) {
  for (let i = 0; i < elements.length; i += 1) {
    const element = elements[i];

    const timestamp = element.getAttribute('datetime');
    if (timestamp) {
      const localDateTime = timestampToLocalDateTime(
        timestamp,
        navigator.language,
        timeOptions,
      );

      element.textContent = localDateTime;
    }
  }
}

function timestampToLocalDateTimeLong(timestamp) {
  // example: "Wednesday, April 3, 2019, 2:55:14 PM"

  return timestampToLocalDateTime(timestamp, navigator.language, {
    weekday: 'long',
    year: 'numeric',
    month: 'long',
    day: 'numeric',
    hour: 'numeric',
    minute: 'numeric',
    second: 'numeric',
  });
}

function timestampToLocalDateTimeShort(timestamp) {
  // example: "10 Dec 2018" if it is not the current year
  // example: "6 Sep" if it is the current year

  if (timestamp) {
    const currentYear = new Date().getFullYear();
    const givenYear = new Date(timestamp).getFullYear();

    var timeOptions = {
      day: 'numeric',
      month: 'short',
    };

    if (givenYear !== currentYear) {
      timeOptions.year = 'numeric';
    }

    return timestampToLocalDateTime(timestamp, navigator.language, timeOptions);
  }

  return '';
}

if (typeof globalThis !== 'undefined') {
  globalThis.timestampToLocalDateTimeLong = timestampToLocalDateTimeLong; // eslint-disable-line no-undef
  globalThis.timestampToLocalDateTimeShort = timestampToLocalDateTimeShort; // eslint-disable-line no-undef
}
