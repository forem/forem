'use strict';

/* eslint-disable no-param-reassign */

function initializeTimeFixer() {
  var utcTime = document.getElementsByClassName('utc-time');
  var utcDate = document.getElementsByClassName('utc-date');
  var utc = document.getElementsByClassName('utc');

  if (!utc) {
    return;
  }

  function convertUtcTime(utcT) {
    var time = new Date(utcTime);
    var options = {
      hour: 'numeric',
      minute: 'numeric',
      timeZoneName: 'short',
    };
    time = new Intl.DateTimeFormat('en-US', options).format(time);
    return time;
  }

  function updateLocalTime(times) {
    var localTime;
    for (var i = 0; i < times.length; i += 1) {
      localTime = convertUtcTime(times[i].dataset.datetime);
      times[i].innerHTML = localTime;
    }
  }

  function convertUtcDate(utcD) {
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
    for (var i = 0; i < dates.length; i += 1) {
      localDate = convertUtcDate(dates[i].dataset.datetime);
      dates[i].innerHTML = localDate;
    }
  }

  function convertCalEvent(UTC) {
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
    for (var i = 0; i < utcTimes.length; i += 1) {
      calTime = convertCalEvent(utcTimes[i].innerHTML);
      utcTimes[i].innerHTML = calTime;
    }
  }

  updateLocalTime(utcTime);
  updateLocalDate(utcDate);
  updateCalendarTime(utc);
}
