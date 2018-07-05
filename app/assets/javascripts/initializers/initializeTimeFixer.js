function initializeTimeFixer() {
  var utcTime = document.getElementsByClassName('utc-time');
  var utcDate = document.getElementsByClassName('utc-date');
  var utc = document.getElementsByClassName('utc');

  if (!utc) {
    return;
  }

  function convertUtcTime(utcTime) {
    var time = new Date(utcTime);
    var options = {
      hour: 'numeric',
      minute: 'numeric',
      timeZoneName: 'short'
    };
    time = new Intl.DateTimeFormat('en-US', options).format(time);
    return time;
  }

  function updateLocalTime(times) {
    var localTime;
    for (var i = 0; i < times.length; i++) {
      localTime = convertUtcTime(times[i].dataset.datetime);
      times[i].innerHTML = localTime;
    }
  }

  function convertUtcDate(utcDate) {
    var date = new Date(utcDate);
    var options = {
      month: 'short',
      day: 'numeric',
    };
    date = new Intl.DateTimeFormat('en-US', options).format(date);
    return date;
  }

  function updateLocalDate(dates) {
    var localDate;
    for (var i = 0; i < dates.length; i++) {
      localDate = convertUtcDate(dates[i].dataset.datetime);
      dates[i].innerHTML = localDate;
    }
  }

  function convertCalEvent(utc) {
    var date = new Date(utc);
    var options = {
      weekday: 'long',
      month: 'long',
      day: 'numeric',
      hour: 'numeric',
      minute: 'numeric',
    };
    date = new Intl.DateTimeFormat('en-US', options).format(date);
    return date;
  }

  function updateCalendarTime(utcTimes) {
    var calTime;
    for (var i = 0; i < utcTimes.length; i++) {
      calTime = convertCalEvent(utcTimes[i].innerHTML);
      utcTimes[i].innerHTML = calTime;
    }
  }

  updateLocalTime(utcTime);
  updateLocalDate(utcDate);
  updateCalendarTime(utc);
}
