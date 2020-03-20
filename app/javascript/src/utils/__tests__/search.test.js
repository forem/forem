import fetch from 'jest-fetch-mock';
import {
  getInitialSearchTerm,
  preloadSearchResults,
  hasInstantClick,
  displaySearchResults,
  fetchSearch,
} from '../search';
import '../../../../assets/javascripts/lib/xss';

global.fetch = fetch;

describe('Search utilities', () => {
  describe('getInitialSearchTerm', () => {
    describe(`When the querystring key 'search_fields' has a value`, () => {
      test(`should return the querystring key search_fields's value`, () => {
        const expected = 'hello';
        const querystring = `?search_fields=${expected}`;
        const actual = getInitialSearchTerm(querystring);
        expect(actual).toEqual(expected);
      });
    });

    describe(`When the querystring key 'search_fields' has a + character representing a space`, () => {
      test(`should return the querystring key search_fields's decoded value with + characters replaced by a space`, () => {
        const expected = `my visual studio setup`;
        const querystring = `?search_fields=my+visual+studio+setup`;
        const actual = getInitialSearchTerm(querystring);
        expect(actual).toEqual(expected);
      });
    });

    describe(`When the querystring key 'search_fields' has an encoded value with markup`, () => {
      test(`should return the querystring key search_fields's decoded value`, () => {
        const expected = `<script>alert('XSS!');</script>`;
        const querystring = `?search_fields=<script>alert(%27XSS!%27);</script>`;
        const actual = getInitialSearchTerm(querystring);
        expect(actual).toEqual(expected);
      });
    });

    describe(`When the querystring key 'search_fields' has no value`, () => {
      test(`should return an empty string`, () => {
        const expected = '';
        const querystring = `?search_fields=`;
        const actual = getInitialSearchTerm(querystring);
        expect(actual).toEqual(expected);
      });
    });

    describe(`When the querystring key 'search_fields' does not exist`, () => {
      test(`should return an empty string`, () => {
        const expected = '';
        const querystring = '?';
        const actual = getInitialSearchTerm(querystring);
        expect(actual).toEqual(expected);
      });
    });
  });

  describe('preloadSearchResults', () => {
    beforeEach(() => {
      global.InstantClick = {
        preload: url => url,
      };
      jest.spyOn(InstantClick, 'preload');
    });

    afterEach(() => {
      jest.restoreAllMocks();
      delete global.InstantClick;
    });

    test('should call InstantClick.preLoad', () => {
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
      test('should call InstantClick.preLoad with the search term value in the URL', () => {
        const location = {
          origin: 'http://localhost',
          href: 'http://localhost',
        };
        const searchTerm = 'hello';
        const expected = `${location.origin}/search?search_fields=${searchTerm}`;

        preloadSearchResults({ searchTerm, location });

        expect(InstantClick.preload).toBeCalledWith(expected);
      });

      test('should call InstantClick.preLoad with the encoded value for the search term', () => {
        const location = {
          origin: 'http://localhost',
          href: 'http://localhost',
        };

        const searchTerm = 'hello+everybody!';
        const expected = `${location.origin}/search?search_fields=hello%2Beverybody%21`;

        preloadSearchResults({ searchTerm, location });

        expect(InstantClick.preload).toBeCalledWith(expected);
      });

      test('should call InstantClick.preLoad if the search term is empty', () => {
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
      test('should return true', () => {
        global.instantClick = {};
        expect(hasInstantClick()).toEqual(true);
        delete global.instantClick;
      });
    });

    describe('When instant click does not exist', () => {
      test('should return false', () => {
        expect(hasInstantClick()).toEqual(false);
      });
    });
  });

  describe('displaySearchResults', () => {
    beforeEach(() => {
      global.InstantClick = {
        display: url => url,
      };
      jest.spyOn(InstantClick, 'display');
    });

    afterEach(() => {
      jest.restoreAllMocks();
      delete global.InstantClick;
    });

    test('should call InstantClick.display if search term is empty', () => {
      displaySearchResults({ searchTerm: '', location: { href: '' } });

      expect(InstantClick.display).toHaveBeenCalledTimes(1);
    });

    test('should call InstantClick.display once', () => {
      displaySearchResults({ searchTerm: 'hello', location: { href: '' } });

      expect(InstantClick.display).toHaveBeenCalledTimes(1);
    });

    test('should call InstantClick.display with the correct search URL', () => {
      const searchTerm = 'hello';
      const location = {
        origin: 'http://localhost',
      };

      displaySearchResults({ searchTerm, location });

      expect(InstantClick.display).toBeCalledWith(
        `${location.origin}/search?search_fields=${searchTerm}`,
      );
    });

    test('should call InstantClick.display with an encoded search term', () => {
      const searchTerm = '#hello%';
      const sanitizedSearchTerm = '%23hello%25';
      const location = {
        origin: 'http://localhost',
      };

      displaySearchResults({ searchTerm, location });

      expect(InstantClick.display).toBeCalledWith(
        `${location.origin}/search?search_fields=${sanitizedSearchTerm}`,
      );
    });

    test('should call InstantClick.display with filters, if present', () => {
      const searchTerm = '#hello%';
      const sanitizedSearchTerm = '%23hello%25';
      const filterParameters = 'class_name:Article';
      const location = {
        origin: 'http://localhost',
        href: `http://localhost?filters=${filterParameters}`,
      };

      displaySearchResults({ searchTerm, location });

      expect(InstantClick.display).toBeCalledWith(
        `${location.origin}/search?search_fields=${sanitizedSearchTerm}&filters=${filterParameters}`,
      );
    });

    test('should not call InstantClick.display with filters, if filter querystring key is present, but has no value', () => {
      const searchTerm = '#hello%';
      const sanitizedSearchTerm = '%23hello%25';
      const location = {
        origin: 'http://localhost',
        href: 'http://localhost?filters=',
      };

      displaySearchResults({ searchTerm, location });

      expect(InstantClick.display).toBeCalledWith(
        `${location.origin}/search?search_fields=${sanitizedSearchTerm}`,
      );
    });
  });

  describe('fetchSearch', () => {
    let responsePromise;
    let dataHash;

    beforeEach(() => {
      fetch.resetMocks();
      fetch.once({});
      dataHash = { name: 'jav' };
      responsePromise = fetchSearch('tags', dataHash);
    });

    test('should return a Promise', () => {
      expect(responsePromise).toBeInstanceOf(Promise);
    });

    test('should return response formatted as JSON', () => {
      responsePromise.then(response => {
        expect(response).toBeInstanceOf(Object);
        expect(response).toMatchObject({ results: expect.any(Array) });
      });
    });
  });
});
