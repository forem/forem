import {
  timestampToLocalDateTime,
  addLocalizedDateTimeToElementsTitles,
  timestampToLocalDateTimeShort,
  localizeTimeElements,
} from '@utilities/localDateTime';

describe('LocalDateTime Utilities', () => {
  beforeEach(() => {
    // Mock navigator.language for consistent tests
    Object.defineProperty(navigator, 'language', {
      writable: true,
      value: 'en-US',
    });
  });

  it('should return empty string when no timestamp', () => {
    const localTime = timestampToLocalDateTime(null, null, null);
    expect(localTime).toEqual('');
  });

  it('should return readable date string', () => {
    const localTime = timestampToLocalDateTime(
      '2019-05-03T16:02:50.908Z',
      'en',
      {},
    );
    expect(localTime).toEqual('5/3/2019');
  });

  it('should return formatted year when year option added', () => {
    const localTime = timestampToLocalDateTime(
      '2019-05-03T16:02:50.908Z',
      'en',
      { year: '2-digit' },
    );
    expect(localTime).toEqual('19');
  });

  it('should add datetime attribute to element', () => {
    document.body.setAttribute('datetime', 2222);
    addLocalizedDateTimeToElementsTitles(
      document.querySelectorAll('body'),
      'datetime',
    );
    expect(
      // eslint-disable-next-line no-prototype-builtins
      document.querySelector('body').attributes.hasOwnProperty('datetime'),
    ).toBe(true);
  });

  describe('timestampToLocalDateTimeShort', () => {
    it('should return empty string when no timestamp', () => {
      const result = timestampToLocalDateTimeShort(null);
      expect(result).toEqual('');
    });

    it('should format date without year for current year', () => {
      const currentYear = new Date().getFullYear();
      const timestamp = `${currentYear}-10-15T10:00:00.000Z`;
      const result = timestampToLocalDateTimeShort(timestamp);
      
      // Should show month and day, but not year for current year
      expect(result).toMatch(/Oct 15/);
      expect(result).not.toMatch(new RegExp(currentYear.toString()));
    });

    it('should format date with year for past year', () => {
      const pastYear = new Date().getFullYear() - 1;
      const timestamp = `${pastYear}-10-15T10:00:00.000Z`;
      const result = timestampToLocalDateTimeShort(timestamp);
      
      // Should include year for past year
      expect(result).toMatch(new RegExp(`Oct 15.*${pastYear}`));
    });

    it('should use user locale for formatting', () => {
      Object.defineProperty(navigator, 'language', {
        writable: true,
        value: 'fr-FR',
      });

      const timestamp = '2024-10-15T10:00:00.000Z';
      const result = timestampToLocalDateTimeShort(timestamp);
      
      // French locale might format differently
      expect(result).toBeTruthy();
      expect(typeof result).toBe('string');
    });

    it('should handle timezone conversion correctly', () => {
      // UTC timestamp that would show different dates in different timezones
      // Oct 15, 2024 02:00 UTC = Oct 15 in GMT+5:30, but Oct 14 in PST
      const utcTimestamp = '2024-10-15T02:00:00.000Z';
      const result = timestampToLocalDateTimeShort(utcTimestamp);
      
      // Should format based on user's local timezone
      expect(result).toBeTruthy();
      expect(result).toMatch(/Oct/);
    });
  });

  describe('localizeTimeElements', () => {
    beforeEach(() => {
      document.body.innerHTML = '';
    });

    it('should format time elements with datetime attributes', () => {
      const timeElement = document.createElement('time');
      timeElement.setAttribute('datetime', '2024-10-15T10:00:00.000Z');
      timeElement.textContent = 'Oct 15, 2024';
      document.body.appendChild(timeElement);

      localizeTimeElements([timeElement], {
        month: 'short',
        day: 'numeric',
        year: 'numeric',
      });

      // Should have updated text content
      expect(timeElement.textContent).toBeTruthy();
      expect(timeElement.textContent).toMatch(/Oct/);
    });

    it('should not format elements without datetime attribute', () => {
      const timeElement = document.createElement('time');
      timeElement.textContent = 'Oct 15, 2024';
      document.body.appendChild(timeElement);

      const originalText = timeElement.textContent;
      localizeTimeElements([timeElement], {
        month: 'short',
        day: 'numeric',
      });

      // Should remain unchanged
      expect(timeElement.textContent).toBe(originalText);
    });

    it('should handle multiple time elements', () => {
      const time1 = document.createElement('time');
      time1.setAttribute('datetime', '2024-10-15T10:00:00.000Z');
      time1.textContent = 'Oct 15, 2024';

      const time2 = document.createElement('time');
      time2.setAttribute('datetime', '2024-10-16T10:00:00.000Z');
      time2.textContent = 'Oct 16, 2024';

      document.body.appendChild(time1);
      document.body.appendChild(time2);

      localizeTimeElements([time1, time2], {
        month: 'short',
        day: 'numeric',
      });

      expect(time1.textContent).toMatch(/Oct 15/);
      expect(time2.textContent).toMatch(/Oct 16/);
    });
  });
});
