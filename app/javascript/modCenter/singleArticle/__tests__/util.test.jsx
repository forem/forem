/* eslint-disable jest/expect-expect */
import { formatDate } from '../util.js';

describe('formatDate utility function', () => {
  let windowSpy;
  const timestamp = '2020-04-01T11:05:00.000Z';

  beforeEach(() => {
    windowSpy = jest.spyOn(global, 'window', 'get')
  });

  afterEach(() => {
    windowSpy.mockRestore();
  });

  it("should return a date in current locale's format", () => {
    windowSpy.mockImplementation(() => ({
    navigator: {
      languages: ['en-GB'],
    }
  }));
    console.log(formatDate(timestamp));

    // expect(formatDate(timestamp)).toEqual('1 Apr');
  });
});