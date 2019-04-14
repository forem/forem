/* Convert server string timestamp to local time, using the user's locale */
function timestampToLocalTime(timestamp, options) {
  if (timestamp === '') {
    return '';
  }

  try {
    var time = new Date(timestamp);
    return new Intl.DateTimeFormat('default', options).format(time);
  } catch (e) {
    return '';
  }
}
