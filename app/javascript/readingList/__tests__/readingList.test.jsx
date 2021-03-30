import { h } from 'preact';
import { render } from '@testing-library/preact';
import { axe } from 'jest-axe';
import fetch from 'jest-fetch-mock';
import { ReadingList } from '../readingList';

describe('<ReadingList />', () => {
  const getMockResponse = () =>
    JSON.stringify({
      result: [
        {
          id: 1234567,
          category: 'readinglist',
          status: 'valid',
          user_id: 1234,
          reactable: {
            id: 123456,
            body_text: 'Some body text',
            class_name: 'Article',
            path: '/bobbytables/what-s-in-your-database-2d3f',
            readable_publish_date_string: 'Jun 22',
            reading_time: 0,
            tags: [
              {
                name: 'css',
                keywords_for_search: null,
              },
              {
                name: 'discuss',
                keywords_for_search: '',
              },
            ],
            title: "What's in your database?",
            user: {
              id: 318840,
              name: 'Bobby Tables',
              profile_image_90: 'https://picsum.photos/90/90',
              username: 'bobbytables',
            },
          },
          last_indexed_at: '2019-06-22T22:03:21.556Z',
        },
      ],
      total: 1,
    });

  beforeEach(() => {
    global.fetch = fetch;
    global.getCsrfToken = jest.fn(() => 'this-is-a-csrf-token');
  });

  afterEach(() => {
    delete global.fetch;
    delete global.getCsrfToken;
  });

  it('should have no a11y violations', async () => {
    fetch.mockResponse(getMockResponse());

    const { container } = render(<ReadingList availableTags={['discuss']} />);
    const results = await axe(container);

    expect(results).toHaveNoViolations();
  });

  it('renders all the elements', () => {
    const { queryByPlaceholderText, queryByText } = render(
      <ReadingList availableTags={['discuss']} />,
    );

    expect(queryByPlaceholderText('search your list')).toBeDefined();
    expect(queryByText('#discuss')).toBeDefined();
    expect(queryByText('View Archive')).toBeDefined();
    expect(queryByText('Your Archive List is Lonely')).toBeDefined();
    expect(queryByText('Reading List (empty)')).toBeDefined();
  });
});
