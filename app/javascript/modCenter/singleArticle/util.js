const months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

function get12HourTime(date) {
  const minutes = date.getMinutes();
  let hours = date.getHours();
  const AmOrPm = hours >= 12 ? 'PM' : 'AM';
  hours = hours % 12 || 12;

  return `${hours}:${minutes} ${AmOrPm}`;
}

export function formatDate(timestamp) {
  const dateToday = new Date();
  const origDatePublished = new Date(timestamp);

  if (dateToday.toDateString() === origDatePublished.toDateString()) {
    return get12HourTime(origDatePublished);
  }
  return `${
    months[origDatePublished.getMonth()]
  } ${origDatePublished.getDate()}`;
}
