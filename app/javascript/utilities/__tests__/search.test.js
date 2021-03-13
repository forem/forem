import fetch from 'jest-fetch-mock';
import {
  getSearchTermFromUrl,
  preloadSearchResults,
  hasInstantClick,
  displaySearchResults,
  fetchSearch,
} from '../search';
import '../../../assets/javascripts/lib/xss';

/* global globalThis */

describe('Search utilities', () => {
  beforeAll(() => {
    const csrfToken = 'this-is-a-csrf-token';

    globalThis.fetch = fetch;
    globalThis.getCsrfToken = async () => csrfToken;
  });
  afterAll(() => {
    delete globalThis.fetch;
    delete globalThis.getCsrfToken;
  });

  describe('getSearchTermFromUrl', () => {
    describe(`When the querystring key 'q' has a value`, () => {
      it(`should return the querystring key q's value`, () => {
        const expected = 'hello';
        const querystring = `?q=${expected}`;
        const actual = getSearchTermFromUrl(querystring);
        expect(actual).toEqual(expected);
      });
    });

    describe(`When the querystring key 'q' has a + character representing a space`, () => {
      it(`should return the querystring key q's decoded value with + characters replaced by a space`, () => {
        const expected = `my visual studio setup`;
        const querystring = `?q=my+visual+studio+setup`;
        const actual = getSearchTermFromUrl(querystring);
        expect(actual).toEqual(expected);
      });
    });

    describe(`When the querystring key 'q' has an encoded value with markup`, () => {
      it(`should return the querystring key q's decoded value`, () => {
        const expected = `<script>alert('XSS!');</script>`;
        const querystring = `?q=<script>alert(%27XSS!%27);</script>`;
        const actual = getSearchTermFromUrl(querystring);
        expect(actual).toEqual(expected);
      });
    });

    describe(`When the querystring key 'q' has no value`, () => {
      it(`should return an empty string`, () => {
        const expected = '';
        const querystring = `?q=`;
        const actual = getSearchTermFromUrl(querystring);
        expect(actual).toEqual(expected);
      });

      it(`should return an empty string when the search term is not defined`, () => {
        /* eslint-disable-next-line no-global-assign */
        filterXSS = jest.fn(() => undefined);
        const querystring = `?q=`;

        const actual = getSearchTermFromUrl(querystring);
        expect(actual).toEqual('');
      });
    });

    describe(`When the querystring key 'q' does not exist`, () => {
      it(`should return an empty string`, () => {
        const expected = '';
        const querystring = '?';
        const actual = getSearchTermFromUrl(querystring);
        expect(actual).toEqual(expected);
      });
    });
  });

  describe('preloadSearchResults', () => {
    beforeEach(() => {
      global.InstantClick = {
        preload: (url) => url,
      };
      jest.spyOn(InstantClick, 'preload');
    });

    afterEach(() => {
      jest.restoreAllMocks();
      delete global.InstantClick;
    });

    it('should call InstantClick.preLoad', () => {
      const location = {
        origin: 'http://localhost',
        href: 'http://localhost',
      };
      preloadSearchResults({
        location,
        searchTerm: 'hello',
      });

      expect(InstantClick.preload).toHaveBeenCalledTimes(1);
    });

    describe('When a search term is passed in', () => {
      it('should call InstantClick.preLoad with the search term value in the URL', () => {
        const location = {
          origin: 'http://localhost',
          href: 'http://localhost',
        };
        const searchTerm = 'hello';
        const expected = `${location.origin}/search?q=${searchTerm}`;

        preloadSearchResults({ searchTerm, location });

        expect(InstantClick.preload).toBeCalledWith(expected);
      });

      it('should call InstantClick.preLoad with the encoded value for the search term', () => {
        const location = {
          origin: 'http://localhost',
          href: 'http://localhost',
        };

        const searchTerm = 'hello+everybody!';
        const expected = `${location.origin}/search?q=hello%2Beverybody%21`;

        preloadSearchResults({ searchTerm, location });

        expect(InstantClick.preload).toBeCalledWith(expected);
      });

      it('should call InstantClick.preLoad if the search term is empty', () => {
        const location = {
          origin: 'http://localhost',
          href: 'http://localhost',
        };
        const searchTerm = '';

        preloadSearchResults({ searchTerm, location });

        expect(InstantClick.preload).toHaveBeenCalledTimes(1);
      });
    });
  });

  describe('hasInstantClick', () => {
    describe('When instant click exists', () => {
      it('should return true', () => {
        global.instantClick = {};
        expect(hasInstantClick()).toEqual(true);
        delete global.instantClick;
      });
    });

    describe('When instant click does not exist', () => {
      it('should return false', () => {
        expect(hasInstantClick()).toEqual(false);
      });
    });
  });

  describe('displaySearchResults', () => {
    beforeEach(() => {
      global.InstantClick = {
        display: (url) => url,
      };
      jest.spyOn(InstantClick, 'display');
    });

    afterEach(() => {
      jest.restoreAllMocks();
      delete global.InstantClick;
    });

    it('should call InstantClick.display if search term is empty', () => {
      displaySearchResults({ searchTerm: '', location: { href: '' } });

      expect(InstantClick.display).toHaveBeenCalledTimes(1);
    });

    it('should call InstantClick.display once', () => {
      displaySearchResults({ searchTerm: 'hello', location: { href: '' } });

      expect(InstantClick.display).toHaveBeenCalledTimes(1);
    });

    it('should call InstantClick.display with the correct search URL', () => {
      const searchTerm = 'hello';
      const location = {
        origin: 'http://localhost',
      };

      displaySearchResults({ searchTerm, location });

      expect(InstantClick.display).toBeCalledWith(
        `${location.origin}/search?q=${searchTerm}`,
      );
    });

    it('should call InstantClick.display with an encoded search term', () => {
      const searchTerm = '#hello%';
      const sanitizedSearchTerm = '%23hello%25';
      const location = {
        origin: 'http://localhost',
      };

      displaySearchResults({ searchTerm, location });

      expect(InstantClick.display).toBeCalledWith(
        `${location.origin}/search?q=${sanitizedSearchTerm}`,
      );
    });

    it('should call InstantClick.display with filters, if present', () => {
      const searchTerm = '#hello%';
      const sanitizedSearchTerm = '%23hello%25';
      const filterParameters = 'class_name:Article';
      const location = {
        origin: 'http://localhost',
        href: `http://localhost?filters=${filterParameters}`,
      };

      displaySearchResults({ searchTerm, location });

      expect(InstantClick.display).toBeCalledWith(
        `${location.origin}/search?q=${sanitizedSearchTerm}&filters=${filterParameters}`,
      );
    });

    it('should not call InstantClick.display with filters, if filter querystring key is present, but has no value', () => {
      const searchTerm = '#hello%';
      const sanitizedSearchTerm = '%23hello%25';
      const location = {
        origin: 'http://localhost',
        href: 'http://localhost?filters=',
      };

      displaySearchResults({ searchTerm, location });

      expect(InstantClick.display).toBeCalledWith(
        `${location.origin}/search?q=${sanitizedSearchTerm}`,
      );
    });
  });

  describe('fetchSearch', () => {
    it('should return response formatted as JSON', async () => {
      const expected = { results: [] };

      fetch.mockResponse(JSON.stringify({ results: [] }));

      const response = await fetchSearch('tags', { name: 'jav' });

      expect(response).toBeInstanceOf(Object);
      expect(response).toMatchObject(expected);
    });
  });
});
