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
