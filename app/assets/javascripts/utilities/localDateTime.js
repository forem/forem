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
  if (timestamp === '') {
    return '';
  }

  try {
    var time = new Date(timestamp);
    return new Intl.DateTimeFormat(locale || 'default', options).format(time);
  } catch (e) {
    return '';
  }
}

function addLocalizedDateTimeToElementsTitles(elements, timestampAttribute) {
  // example: "Wednesday, April 3, 2019, 2:55:14 PM"
  var timeOptions = {
    weekday: 'long',
    year: 'numeric',
    month: 'long',
    day: 'numeric',
    hour: 'numeric',
    minute: 'numeric',
    second: 'numeric',
  };

  for (var i = 0; i < elements.length; i += 1) {
    var element = elements[i];

    // get UTC timestamp set by the server
    var timestamp = element.getAttribute(timestampAttribute || 'datetime');

    if (timestamp) {
      // add a full datetime to the element title, visible on hover.
      // `navigator.language` is used to allow the date to be localized
      // according to the browser's locale
      // see <https://developer.mozilla.org/en-US/docs/Web/API/NavigatorLanguage/language>
      var localDateTime = timestampToLocalDateTime(
        timestamp,
        navigator.language,
        timeOptions,
      );
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
