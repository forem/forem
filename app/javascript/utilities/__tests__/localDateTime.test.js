import {
  timestampToLocalDateTime,
  addLocalizedDateTimeToElementsTitles,
} from '@utilities/localDateTime';

describe('LocalDateTime Utilities', () => {
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
});
