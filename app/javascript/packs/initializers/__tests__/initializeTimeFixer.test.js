import {
  initializeTimeFixer,
  convertUtcDate,
  convertUtcTime,
  formatDateTime,
  updateLocalDateTime,
  convertCalEvent,
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
    // const formatDateTime = jest.fn();

    expect(dateConversion).toContain('Feb 2');
  });

  test('convertUtcDate function with different options', () => {
    const utcDate = '2022-03-04T10:30:00.000Z';

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

  test('formatDateTime function with different options and values', () => {
    const options1 = {
      hour: 'numeric',
      minute: 'numeric',
      timeZoneName: 'short',
    };
    const value1 = new Date('2022-03-04T10:30:00.000Z');
    expect(formatDateTime(options1, value1)).toBe('10:30 AM UTC');

    const options2 = {
      year: 'numeric',
      month: 'short',
      day: 'numeric',
    };
    const value2 = new Date('2022-03-04T10:30:00.000Z');
    expect(formatDateTime(options2, value2)).toBe('Mar 4, 2022');
  });
});

describe('formatDateTime', () => {
  it('formats the date time with given options', () => {
    const options = {
      month: 'short',
      day: 'numeric',
      year: 'numeric',
      hour: 'numeric',
      minute: 'numeric',
    };
    const value = new Date('2022-04-13T12:34:56Z');
    const expected = 'Apr 13, 2022, 12:34 PM';

    expect(formatDateTime(options, value)).toEqual(expected);
  });
});

describe('convertUtcTime', () => {
  it('converts the UTC time to local time with proper format', () => {
    const utcTime = '2022-04-13T12:34:56Z';
    const expected = '12:34 PM UTC';

    expect(convertUtcTime(utcTime)).toEqual(expected);
  });
});

describe('convertUtcDate', () => {
  it('converts the UTC date to local date with proper format', () => {
    const utcDate = '2022-04-13T12:34:56Z';
    const expected = expect.stringMatching(/^\w{3} \d{1,2}$/);

    expect(convertUtcDate(utcDate)).toEqual(expected);
  });
});

describe('updateLocalDateTime', () => {
  it('updates the innerHTML of given elements with local time', () => {
    document.body.innerHTML = `
      <div>
        <span class="utc-time" data-datetime="2022-04-13T12:34:56Z">12:34 PM</span>
        <span class="utc-date" data-datetime="2022-04-13T12:34:56Z">Apr 13</span>
        <span class="utc">Wednesday, April 13, 2022, 12:34 PM</span>
      </div>
    `;

    const utcTimeElements = document.querySelectorAll('.utc-time');
    const utcDateElements = document.querySelectorAll('.utc-date');
    const utcElements = document.querySelectorAll('.utc');

    updateLocalDateTime(
      utcTimeElements,
      convertUtcTime,
      (element) => element.dataset.datetime,
    );
    updateLocalDateTime(
      utcDateElements,
      convertUtcDate,
      (element) => element.dataset.datetime,
    );
    updateLocalDateTime(
      utcElements,
      convertCalEvent,
      (element) => element.innerHTML,
    );

    expect(utcTimeElements[0].innerHTML).toEqual('12:34 PM UTC');
    expect(utcDateElements[0].innerHTML).toEqual(
      expect.stringMatching(/^\w{3} \d{1,2}$/),
    );
    expect(utcElements[0].innerHTML).toEqual('Wednesday, April 13 at 12:34 PM');
  });
});
