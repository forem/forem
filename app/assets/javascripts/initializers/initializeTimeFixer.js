'use strict';

/* eslint-disable no-param-reassign */
function convertUtcTime(utcTime) {
  var time = new Date(utcTime);
  var options = {
    hour: 'numeric',
    minute: 'numeric',
    timeZoneName: 'short',
  };
  time = new Intl.DateTimeFormat('en-US', options).format(time);
  return time;
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

function updateLocalDateOrTime(property, callBack) {
  var local;
  for (var i = 0; i < property.length; i += 1) {
    local = callBack(property[i].dataset.datetime);
    property[i].innerHTML = local;
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
  for (var i = 0; i < utcTimes.length; i += 1) {
    calTime = convertCalEvent(utcTimes[i].innerHTML);
    utcTimes[i].innerHTML = calTime;
  }
}

function initializeTimeFixer() {
  var utcTime = document.getElementsByClassName('utc-time');
  var utcDate = document.getElementsByClassName('utc-date');
  var utc = document.getElementsByClassName('utc');

  if (!utc) {
    return;
  }

  updateLocalDateOrTime(utcTime);
  updateLocalDateOrTime(utcDate);
  updateCalendarTime(utc);
}
