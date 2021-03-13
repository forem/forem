import '../../../assets/javascripts/utilities/timeAgo';

/* global globalThis timeAgo */

describe('timeAgo', () => {
  afterAll(() => {
    delete globalThis.timeAgo;
  });

  it('should return "just now" for a date that is now.', () => {
    const oldTimeInSeconds = new Date().getTime();

    expect(timeAgo({ oldTimeInSeconds })).toEqual(
      '<span class="time-ago-indicator">(just now)</span>',
    );
  });

  it('should support a custom string formatter for the time.', () => {
    const oldTimeInSeconds = new Date().getTime();

    expect(
      timeAgo({
        oldTimeInSeconds,
        formatter: (x) => `[${x}]`,
      }),
    ).toEqual('[just now]');
  });

  it('should return "1 min ago" for a date that is one minute in the past.', () => {
    const oneMinute = 60000;
    const oldTimeInSeconds = new Date(new Date().getTime() - oneMinute) / 1000;

    expect(timeAgo({ oldTimeInSeconds })).toEqual(
      '<span class="time-ago-indicator">(1 min ago)</span>',
    );
  });

  it('should return "n mins ago" for a date that is n minutes in the past.', () => {
    const fiveMinutes = 5 * 60000;
    const oldTimeInSeconds =
      new Date(new Date().getTime() - fiveMinutes) / 1000;

    expect(timeAgo({ oldTimeInSeconds })).toEqual(
      '<span class="time-ago-indicator">(5 mins ago)</span>',
    );
  });

  it('should return "1 hour ago" for a date that is one hour in the past.', () => {
    const oneHour = 60 * 60000;
    const oldTimeInSeconds = new Date(new Date().getTime() - oneHour) / 1000;

    expect(timeAgo({ oldTimeInSeconds })).toEqual(
      '<span class="time-ago-indicator">(1 hour ago)</span>',
    );
  });

  it('should return "n hours ago" for a date that is n hours in the past', () => {
    const fiveHours = 5 * 60 * 60000;
    const oldTimeInSeconds = new Date(new Date().getTime() - fiveHours) / 1000;

    expect(timeAgo({ oldTimeInSeconds })).toEqual(
      '<span class="time-ago-indicator">(5 hours ago)</span>',
    );
  });

  describe('Custom maxDisplayedAge to support days, weeks, months and years', () => {
    it('should return "1 day ago" for a date is one day in the past.', () => {
      const oneDay = 24 * 60 * 60000;
      const oldTimeInSeconds = new Date(new Date().getTime() - oneDay) / 1000;
      const maxDisplayedAge = oneDay;

      expect(timeAgo({ oldTimeInSeconds, maxDisplayedAge })).toEqual(
        '<span class="time-ago-indicator">(1 day ago)</span>',
      );
    });

    it('should return "n days ago" for a date is that is n days in the past.', () => {
      const fiveDays = 5 * 24 * 60 * 60000;
      const oldTimeInSeconds = new Date(new Date().getTime() - fiveDays) / 1000;
      const maxDisplayedAge = fiveDays;

      expect(timeAgo({ oldTimeInSeconds, maxDisplayedAge })).toEqual(
        '<span class="time-ago-indicator">(5 days ago)</span>',
      );
    });

    it('should return "1 month ago" for a date is one month in the past.', () => {
      const oneMonth = 31 * 24 * 60 * 60000;
      const oldTimeInSeconds = new Date(new Date().getTime() - oneMonth) / 1000;
      const maxDisplayedAge = oneMonth;

      expect(timeAgo({ oldTimeInSeconds, maxDisplayedAge })).toEqual(
        '<span class="time-ago-indicator">(1 month ago)</span>',
      );
    });

    it('should return "n days ago" for a date is that is n months in the past.', () => {
      const fiveMonths = 31 * 5 * 24 * 60 * 60000;
      const oldTimeInSeconds =
        new Date(new Date().getTime() - fiveMonths) / 1000;
      const maxDisplayedAge = fiveMonths;

      expect(timeAgo({ oldTimeInSeconds, maxDisplayedAge })).toEqual(
        '<span class="time-ago-indicator">(5 months ago)</span>',
      );
    });

    it('should return "1 year ago" for a date is one month in the past.', () => {
      const oneYear = 365 * 24 * 60 * 60000;
      const oldTimeInSeconds = new Date(new Date().getTime() - oneYear) / 1000;
      const maxDisplayedAge = oneYear;

      expect(timeAgo({ oldTimeInSeconds, maxDisplayedAge })).toEqual(
        '<span class="time-ago-indicator">(1 year ago)</span>',
      );
    });

    it('should return "n years ago" for a date is that is n years in the past.', () => {
      const fiveYears = 365 * 5 * 24 * 60 * 60000;
      const oldTimeInSeconds =
        new Date(new Date().getTime() - fiveYears) / 1000;
      const maxDisplayedAge = fiveYears;

      expect(timeAgo({ oldTimeInSeconds, maxDisplayedAge })).toEqual(
        '<span class="time-ago-indicator">(5 years ago)</span>',
      );
    });
  });
});
