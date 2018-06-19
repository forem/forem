function updateLocalTime(times) {
  function convertUtcTime(timestamp) {
    var time = new Date(timestamp);
    var options = {
      hour: 'numeric',
      minute: 'numeric',
    };
    time = new Intl.DateTimeFormat('en-US', options).format(time);
    return time;
  }
  for (var i = 0; i < times.length; i++) {
    localTime = convertUtcTime(times[i].innerHTML);
    times[i].innerHTML = localTime;
  }
}
