function timeAgo(oldTimeInSeconds) {
  var seconds = new Date() / 1000;
  var times = [
    ['second', 1],
    ['min', 60],
    ['hour', 3600],
    ['day', 86400],
    ['week', 604800],
    ['month', 2592000],
    ['year', 31536000],
  ];
  var t;
  var diff = Math.round(seconds - oldTimeInSeconds);
  for (t = 0; t < times.length; t++) {
    if (diff < times[t][1]) {
      if (t === 0) {
        return "<span class='time-ago-indicator'>(Just now)</span>";
      }
      if (t < 4) {
        diff = Math.round(diff / times[t - 1][1]);
        return (
          "<span class='time-ago-indicator'>(" +
          diff +
          ' ' +
          times[t - 1][0] +
          (diff === 1 ? ' ago' : 's ago') +
          ')</span>'
        );
      }
      return '';
    }
  }
}
