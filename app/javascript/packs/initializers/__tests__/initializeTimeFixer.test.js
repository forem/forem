import { initializeTimeFixer, convertUtcDate } from "../initializeTimeFixer";

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

  test('should convert UTC date', async () => {
    const utcDate = Date.UTC(96, 1, 2, 3, 4, 5);
    const dateConversion = convertUtcDate(utcDate);

    expect(dateConversion).toContain('Feb 1');
  });
});