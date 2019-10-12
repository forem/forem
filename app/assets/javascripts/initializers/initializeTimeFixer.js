'use strict';

/* eslint-disable no-param-reassign */

function getFormat(options, formatValue) {
  return new Intl.DateTimeFormat('en-US', options).format(formatValue);
}

function convertUtcTime(utcTime) {
  var time = new Date(utcTime);
  var options = {
    hour: 'numeric',
    minute: 'numeric',
    timeZoneName: 'short',
  };
  return getFormat(options, time);
}

function convertUtcDate(utcDate) {
  var date = new Date(utcDate);
  var options = {
    month: 'short',
    day: 'numeric',
  };
  return getFormat(options, date);
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

  return getFormat(options, date);
}

function updateLocal(elements, convertCallback) {
  var local;
  for (var i = 0; i < elements.length; i += 1) {
    local = convertCallback(elements[i].dataset.datetime);
    elements[i].innerHTML = local;
  }
}

function initializeTimeFixer() {
  var utcTime = document.getElementsByClassName('utc-time');
  var utcDate = document.getElementsByClassName('utc-date');
  var utc = document.getElementsByClassName('utc');

  if (!utc) {
    return;
  }

  updateLocal(utcTime, convertUtcTime);
  updateLocal(utcDate, convertUtcDate);
  updateLocal(utc, convertCalEvent);
}
