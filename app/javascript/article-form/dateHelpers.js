const MONTH_NAMES = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

function pad2(num) {
  return String(num).padStart(2, '0');
}

/**
 * Parses an ISO timestamp, Date object, or local `'YYYY-MM-DD HH:mm'` string into a Date.
 *
 * @param {Date|string|number} input
 * @returns {Date}
 */
export function parseArticleDate(input) {
  if (input instanceof Date) {
    return new Date(input.getTime());
  }
  if (typeof input === 'string') {
    const localMatch =
      /^(\d{4})-(\d{2})-(\d{2})(?:[ T](\d{2}):(\d{2})(?::(\d{2}))?)?$/.exec(
        input.trim(),
      );
    if (localMatch) {
      const [, year, month, day, hour = '0', minute = '0', second = '0'] =
        localMatch;
      return new Date(
        Number(year),
        Number(month) - 1,
        Number(day),
        Number(hour),
        Number(minute),
        Number(second),
      );
    }
  }
  return new Date(input);
}

/**
 * Formats a Date as `'YYYY-MM-DD'` in local time.
 *
 * @param {Date} date
 * @returns {string}
 */
export function formatYYYYMMDD(date) {
  return `${date.getFullYear()}-${pad2(date.getMonth() + 1)}-${pad2(
    date.getDate(),
  )}`;
}

/**
 * Formats a Date as 24-hour `'HH:mm'` in local time.
 *
 * @param {Date} date
 * @returns {string}
 */
export function formatHHmm(date) {
  return `${pad2(date.getHours())}:${pad2(date.getMinutes())}`;
}

/**
 * Formats a Date as 12-hour `'h:mm A'` (e.g. `'2:30 PM'`) in local time.
 *
 * @param {Date} date
 * @returns {string}
 */
export function format12HourTime(date) {
  const hours24 = date.getHours();
  const period = hours24 >= 12 ? 'PM' : 'AM';
  const hours12 = hours24 % 12 || 12;
  return `${hours12}:${pad2(date.getMinutes())} ${period}`;
}

/**
 * Formats a Date as `'MMMM D, YYYY'` (e.g. `'November 3, 2026'`) in local time.
 *
 * @param {Date} date
 * @returns {string}
 */
export function formatLongDate(date) {
  return `${
    MONTH_NAMES[date.getMonth()]
  } ${date.getDate()}, ${date.getFullYear()}`;
}

/**
 * Formats a Date as `'MMMM D, YYYY at h:mm A'` in local time.
 *
 * @param {Date} date
 * @returns {string}
 */
export function formatScheduleDateTime(date) {
  return `${formatLongDate(date)} at ${format12HourTime(date)}`;
}
