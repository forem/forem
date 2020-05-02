import { updateListings, getQueryParams, getLocation } from '../utils';

describe('updateListings', () => {
  const firstListing = {
    id: 20,
    category: 'misc',
    location: 'West Refugio',
    bumped_at: '2019-06-11T17:01:25.143Z',
    processed_html:
      '\u003cp\u003eEius et ullam. Dolores et qui. Quis \u003cstrong\u003equi\u003c/strong\u003e omnis.\u003c/p\u003e\n',
    slug: 'illo-iure-quos-htyashsayas-5hk7',
    title: 'Mentor wanted',
    tags: ['go', 'git'],
    user_id: 1,
    author: {
      name: 'Mrs. Yoko Christiansen',
      username: 'mrschristiansenyoko',
      profile_image_90:
        '/uploads/user/profile_image/7/4b1c980a-beb0-4a5f-b3f2-acc91adc503c.png',
    },
  };

  const secondtListing = {
    id: 21,
    category: 'misc',
    location: 'West Refugio',
    bumped_at: '2019-06-11T17:01:25.143Z',
    processed_html:
      '\u003cp\u003eEius et ullam. Dolores et qui. Quis \u003cstrong\u003equi\u003c/strong\u003e omnis.\u003c/p\u003e\n',
    slug: 'illo-iure-quos-ereerr-5hk7',
    title: 'Second tag.',
    tags: ['functional', 'clojure'],
    user_id: 1,
    author: {
      name: 'Mrs. Ashahir',
      username: 'mrschristiansenyoko',
      profile_image_90:
        '/uploads/user/profile_image/7/4b1c980a-beb0-4a5f-b3f2-acc91adc503c.png',
    },
  };

  const thirdListing = {
    id: 22,
    category: 'misc',
    location: 'West Refugio',
    processed_html:
      '\u003cp\u003eEius et ullam. Dolores et qui. Quis \u003cstrong\u003equi\u003c/strong\u003e omnis.\u003c/p\u003e\n',
    slug: 'illo-iure-fss-ssasas-5hk7',
    title: 'Illo iure quos perspiciatis.',
    tags: ['twitter', 'learning'],
    user_id: 1,
    author: {
      name: 'Mrs. John Mack',
      username: 'mrschristiansenyoko',
      profile_image_90:
        '/uploads/user/profile_image/7/4b1c980a-beb0-4a5f-b3f2-acc91adc503c.png',
    },
  };

  const classifiedListings = [firstListing, secondtListing, thirdListing];
  test('Should update the listings', () => {
    const result = updateListings(classifiedListings);
    const expectedResult = [firstListing, secondtListing];

    expect(result).toEqual(expectedResult);
  });
});

describe('updateListings', () => {
  beforeEach(() => {
    window.history.pushState(
      {},
      'Test Title',
      '/test.html?crcat=test&crsource=test&crkw=buy-a-lot',
    );
  });

  test('Should get the query params', () => {
    const result = getQueryParams();
    const expectedResult = {
      crcat: 'test',
      crkw: 'buy-a-lot',
      crsource: 'test',
    };

    expect(result).toEqual(expectedResult);
  });
});

describe('getLocation', () => {
  let slug;
  let tags;
  let category;
  let query;

  test('Should return a location with slug and category', () => {
    slug = 'slug';
    tags = ['clojure', 'functional'];
    category = 'clojure';
    query = 'test&crsource=test&crkw=buy-a-lot';

    const result = getLocation({ query, tags, category, slug });
    const expectedResult = `/listings/${category}/${slug}`;

    expect(result).toEqual(expectedResult);
  });

  test('Should return a location with category, query and tags', () => {
    slug = undefined;
    tags = ['clojure', 'functional'];
    category = 'clojure';
    query = 'test&crsource=test&crkw=buy-a-lot';

    const result = getLocation({ query, tags, category, slug });
    const expectedResult = `/listings/${category}?q=${query}&t=${tags}`;

    expect(result).toEqual(expectedResult);
  });

  test('Should return a location with category and query', () => {
    slug = undefined;
    tags = [];
    category = 'clojure';
    query = 'test&crsource=test&crkw=buy-a-lot';

    const result = getLocation({ query, tags, category, slug });
    const expectedResult = `/listings/${category}?q=${query}`;

    expect(result).toEqual(expectedResult);
  });

  test('Should return a location with category and tags', () => {
    slug = undefined;
    tags = ['clojure', 'functional'];
    category = 'clojure';
    query = '';

    const result = getLocation({ query, tags, category, slug });
    const expectedResult = `/listings/${category}?t=${tags}`;

    expect(result).toEqual(expectedResult);
  });

  test('Should return a location with category', () => {
    slug = undefined;
    tags = [];
    category = 'clojure';
    query = '';

    const result = getLocation({ query, tags, category, slug });
    const expectedResult = `/listings/${category}`;

    expect(result).toEqual(expectedResult);
  });

  test('Should return just the URL base', () => {
    slug = undefined;
    tags = [];
    category = '';
    query = '';

    const result = getLocation({ query, tags, category, slug });
    const expectedResult = '/listings';

    expect(result).toEqual(expectedResult);
  });
});
