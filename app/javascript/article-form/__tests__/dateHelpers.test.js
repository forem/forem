import {
  parseArticleDate,
  formatYYYYMMDD,
  formatHHmm,
  format12HourTime,
  formatLongDate,
  formatScheduleDateTime,
} from '../dateHelpers';

describe('article-form dateHelpers', () => {
  it('parses YYYY-MM-DD HH:mm strings in local time', () => {
    const parsed = parseArticleDate('2026-11-03 14:05');
    expect(parsed.getFullYear()).toBe(2026);
    expect(parsed.getMonth()).toBe(10); // November (0-indexed)
    expect(parsed.getDate()).toBe(3);
    expect(parsed.getHours()).toBe(14);
    expect(parsed.getMinutes()).toBe(5);
  });

  it('formats YYYY-MM-DD and HH:mm strings', () => {
    const date = new Date(2026, 10, 3, 9, 5);
    expect(formatYYYYMMDD(date)).toEqual('2026-11-03');
    expect(formatHHmm(date)).toEqual('09:05');
  });

  it('formats 12-hour time, long date, and combined schedule string', () => {
    const afternoon = new Date(2026, 10, 3, 14, 5);
    const midnight = new Date(2026, 0, 15, 0, 30);

    expect(format12HourTime(afternoon)).toEqual('2:05 PM');
    expect(format12HourTime(midnight)).toEqual('12:30 AM');
    expect(formatLongDate(afternoon)).toEqual('November 3, 2026');
    expect(formatScheduleDateTime(afternoon)).toEqual(
      'November 3, 2026 at 2:05 PM',
    );
  });
});
