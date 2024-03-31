jest.mock('@utilities/localDateTime', () => ({
  timestampToLocalDateTime: jest.fn(),
}));

import { setupRssFetchTime } from '../rssFetchTime';
import { timestampToLocalDateTime } from '@utilities/localDateTime';

describe('RSSFetchTime Tests', () => {
  beforeAll(async () => {
    document.body.innerHTML =
      '<time id="rss-fetch-time" datetime="2023-07-10T20:02:16Z"></time>';
  });

  it('timestampToLocalDateTime is called', () => {
    setupRssFetchTime();
    expect(timestampToLocalDateTime).toHaveBeenCalled();
  });
});
