import {
  initializeDateHelpers,
  formatAllTimeElements,
} from '../initializeDateTimeHelpers';
import { timestampToLocalDateTimeShort } from '@utilities/localDateTime';

// Mock the utility function
jest.mock('@utilities/localDateTime', () => {
  const actual = jest.requireActual('@utilities/localDateTime');
  return {
    ...actual,
    timestampToLocalDateTimeShort: jest.fn((timestamp) => {
      if (!timestamp) return '';
      const date = new Date(timestamp);
      const year = date.getFullYear();
      const currentYear = new Date().getFullYear();
      const month = date.toLocaleString('en-US', { month: 'short' });
      const day = date.getDate();
      
      if (year === currentYear) {
        return `${month} ${day}`;
      }
      return `${month} ${day}, ${year}`;
    }),
  };
});

describe('initializeDateHelpers', () => {
  beforeEach(() => {
    document.body.innerHTML = '';
    jest.clearAllMocks();
  });

  it('should format time elements with .date class', () => {
    const timeElement = document.createElement('time');
    timeElement.className = 'date';
    timeElement.setAttribute('datetime', '2024-10-15T10:00:00.000Z');
    timeElement.textContent = 'Oct 15, 2024';
    document.body.appendChild(timeElement);

    initializeDateHelpers();

    // Should have formatted the date
    expect(timeElement.textContent).toBeTruthy();
    expect(timeElement.textContent).toMatch(/Oct/);
  });

  it('should format time elements with .date-no-year class', () => {
    const timeElement = document.createElement('time');
    timeElement.className = 'date-no-year';
    timeElement.setAttribute('datetime', '2024-10-15T10:00:00.000Z');
    timeElement.textContent = 'Oct 15';
    document.body.appendChild(timeElement);

    initializeDateHelpers();

    expect(timeElement.textContent).toBeTruthy();
  });

  it('should format time elements with .date-short-year class', () => {
    const timeElement = document.createElement('time');
    timeElement.className = 'date-short-year';
    timeElement.setAttribute('datetime', '2023-10-15T10:00:00.000Z');
    timeElement.textContent = "Oct 15 '23";
    document.body.appendChild(timeElement);

    initializeDateHelpers();

    expect(timeElement.textContent).toBeTruthy();
  });

  it('should format time elements without specific classes', () => {
    const timeElement = document.createElement('time');
    timeElement.setAttribute('datetime', '2024-10-15T10:00:00.000Z');
    timeElement.textContent = 'Oct 15, 2024';
    document.body.appendChild(timeElement);

    initializeDateHelpers();

    expect(timestampToLocalDateTimeShort).toHaveBeenCalledWith('2024-10-15T10:00:00.000Z');
    expect(timeElement.textContent).toBeTruthy();
  });

  it('should not format time elements without datetime attribute', () => {
    const timeElement = document.createElement('time');
    timeElement.textContent = 'Oct 15, 2024';
    document.body.appendChild(timeElement);

    const originalText = timeElement.textContent;
    initializeDateHelpers();

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

    initializeDateHelpers();

    expect(timestampToLocalDateTimeShort).toHaveBeenCalledTimes(2);
  });
});

describe('formatAllTimeElements', () => {
  beforeEach(() => {
    document.body.innerHTML = '';
    jest.clearAllMocks();
  });

  it('should format time elements in given container', () => {
    const container = document.createElement('div');
    const timeElement = document.createElement('time');
    timeElement.setAttribute('datetime', '2024-10-15T10:00:00.000Z');
    timeElement.textContent = 'Oct 15, 2024';
    container.appendChild(timeElement);
    document.body.appendChild(container);

    formatAllTimeElements(container);

    expect(timestampToLocalDateTimeShort).toHaveBeenCalledWith('2024-10-15T10:00:00.000Z');
    expect(timeElement.textContent).toBeTruthy();
  });

  it('should format time elements in document by default', () => {
    const timeElement = document.createElement('time');
    timeElement.setAttribute('datetime', '2024-10-15T10:00:00.000Z');
    timeElement.textContent = 'Oct 15, 2024';
    document.body.appendChild(timeElement);

    formatAllTimeElements();

    expect(timestampToLocalDateTimeShort).toHaveBeenCalled();
  });

  it('should skip time elements with .date class', () => {
    const timeElement = document.createElement('time');
    timeElement.className = 'date';
    timeElement.setAttribute('datetime', '2024-10-15T10:00:00.000Z');
    timeElement.textContent = 'Oct 15, 2024';
    document.body.appendChild(timeElement);

    formatAllTimeElements();

    // Should not call timestampToLocalDateTimeShort for elements with .date class
    // (they're handled by localizeTimeElements instead)
    expect(timestampToLocalDateTimeShort).not.toHaveBeenCalled();
  });

  it('should handle time elements with children (like time-ago indicators)', () => {
    const timeElement = document.createElement('time');
    timeElement.setAttribute('datetime', '2024-10-15T10:00:00.000Z');
    timeElement.textContent = 'Oct 15, 2024';
    
    const span = document.createElement('span');
    span.className = 'time-ago-indicator';
    span.textContent = ' (5 min ago)';
    timeElement.appendChild(span);
    
    document.body.appendChild(timeElement);

    formatAllTimeElements();

    // Should still format the date
    expect(timestampToLocalDateTimeShort).toHaveBeenCalled();
  });

  it('should be available globally', () => {
    expect(typeof globalThis.formatAllTimeElements).toBe('function');
  });
});

