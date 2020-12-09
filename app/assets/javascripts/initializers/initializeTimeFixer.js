'use strict';

function formatDateTime(options, value) {
  return new Intl.DateTimeFormat('en-US', options).format(value);
}

function convertUtcTime(utcTime) {
  var time = new Date(utcTime);
  var options = {
    hour: 'numeric',
    minute: 'numeric',
    timeZoneName: 'short',
  };
  return formatDateTime(options, time);
}

function convertUtcDate(utcDate) {
  var date = new Date(utcDate);
  var options = {
    month: 'short',
    day: 'numeric',
  };
  return formatDateTime(options, date);
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

  return formatDateTime(options, date);
}

function updateLocalDateTime(elements, convertCallback, getUtcDateTime) {
  var local;
  for (var i = 0; i < elements.length; i += 1) {
    local = convertCallback(getUtcDateTime(elements[i]));
    // eslint-disable-next-line no-param-reassign
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

  updateLocalDateTime(
    utcTime,
    convertUtcTime,
    (element) => element.dataset.datetime,
  );
  updateLocalDateTime(
    utcDate,
    convertUtcDate,
    (element) => element.dataset.datetime,
  );
  updateLocalDateTime(utc, convertCalEvent, (element) => element.innerHTML);
}
