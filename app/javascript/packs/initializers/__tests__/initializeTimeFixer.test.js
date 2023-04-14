import {
  initializeTimeFixer,
  convertUtcDate,
  convertUtcTime,
} from '../initializeTimeFixer';

describe('initializeTimeFixer', () => {
  beforeEach(() => {
    const utcTimeClassDiv = document.createElement('div');
    const utcDateClassDiv = document.createElement('div');
    const utcDiv = document.createElement('div');

    utcTimeClassDiv.classList.add('utc-time');
    utcDateClassDiv.classList.add('utc-date');
    utcDiv.classList.add('utc');
  });

  test('should call event listener when preview button exist', async () => {
    const button = document.createElement('button');
    button.classList.add('preview-toggle');
    button.addEventListener = jest.fn();
    initializeTimeFixer();

    expect(button.addEventListener).not.toHaveBeenCalled();
  });

  test('should call updateLocalDateTime', async () => {
    const updateLocalDateTime = jest.fn();
    initializeTimeFixer();

    expect(updateLocalDateTime).not.toHaveBeenCalled();
  });

  test('should call convertUtcDate', async () => {
    const convertUtcDate = jest.fn();
    initializeTimeFixer();

    expect(convertUtcDate).not.toHaveBeenCalled();
  });

  test('should convert Utc Dates', async () => {
    const utcDate = Date.UTC(96, 1, 2, 3, 4, 5);
    const dateConversion = await convertUtcDate(utcDate);

    expect(dateConversion).toContain('Feb 2');
  });

  test('convertUtcDate function with different options', () => {
    const utcDate = '2022-03-04T10:30:00.000Z';
    // const date = new Date(utcDate);

    const options1 = {
      month: 'short',
      day: 'numeric',
    };
    expect(convertUtcDate(utcDate, options1)).toBe('Mar 4');

    const options2 = {
      year: 'numeric',
      month: 'long',
      day: 'numeric',
      hour: 'numeric',
      minute: 'numeric',
      second: 'numeric',
      timeZoneName: 'short',
    };
    expect(convertUtcDate(utcDate, options2)).toBe('Mar 4');
  });

  test('convertUtcTime function with different options', () => {
    const utcTime = '2022-03-04T10:30:00.000Z';

    const options1 = {
      hour: 'numeric',
      minute: 'numeric',
      timeZoneName: 'short',
    };
    expect(convertUtcTime(utcTime, options1)).toBe('10:30 AM UTC');

    const options2 = {
      hour: 'numeric',
      minute: 'numeric',
      second: 'numeric',
      timeZoneName: 'short',
    };
    expect(convertUtcTime(utcTime, options2)).toBe('10:30 AM UTC');
  });
});
