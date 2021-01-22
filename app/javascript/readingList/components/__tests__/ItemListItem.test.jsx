import { h } from 'preact';
import { render } from '@testing-library/preact';
import { axe } from 'jest-axe';
import { ItemListItem } from '../ItemListItem';

function getItem() {
  return {
    reactable: {
      path: '/article',
      title: 'Title',
      readable_publish_date_string: 'Jun 29',
      reading_time: 1,
      user: {
        username: 'bob',
        profile_image_90: 'https://dummyimage.com/90x90',
        name: 'Bob',
      },
      tags: [{ name: 'discuss' }],
    },
  };
}

describe('<ItemListItem />', () => {
  it('should have no a11y violations', async () => {
    const { container } = render(<ItemListItem item={getItem()} />);
    const results = await axe(container);

    expect(results).toHaveNoViolations();
  });

  it('renders the title', () => {
    const { queryByText } = render(<ItemListItem item={getItem()} />);

    expect(queryByText(/Title/i)).toBeDefined();
  });

  it('renders the path', () => {
    const { getByText } = render(<ItemListItem item={getItem()} />);

    expect(getByText(/Title/i).closest('a').getAttribute('href')).toBe(
      '/article',
    );
  });

  it('renders a published date', () => {
    const { queryByText } = render(<ItemListItem item={getItem()} />);

    expect(queryByText(/Jun 29/i)).toBeDefined();
  });

  it('renders a profile_image', () => {
    const { getByAltText } = render(<ItemListItem item={getItem()} />);

    expect(getByAltText(/Bob/i).getAttribute('src')).toBe(
      'https://dummyimage.com/90x90',
    );
  });

  it('renders with readingtime of 1 min if reading time is less than 1 min.', () => {
    const item = getItem();
    item.reactable.reading_time = 0.5;

    const { queryByText } = render(<ItemListItem item={item} />);

    expect(queryByText(/1 min read/i)).toBeDefined();
  });

  it('renders with readingtime of 1 min if reading time is null.', () => {
    const item = getItem();
    item.reactable.reading_time = null;

    const { queryByText } = render(<ItemListItem item={item} />);

    expect(queryByText(/1 min read/i)).toBeDefined();
  });

  it('renders correct readingtime.', () => {
    const item = getItem();
    item.reactable.reading_time = 10;

    const { queryByText } = render(<ItemListItem item={item} />);

    expect(queryByText(/10 min read/i)).toBeDefined();
  });

  it('renders without any tags if the tags array is empty.', () => {
    const item = getItem();
    item.reactable.tags = [];

    const { queryByTestId } = render(<ItemListItem item={item} />);

    expect(queryByTestId('item-tags')).toBeNull();
  });

  it('renders tags with links if present.', () => {
    const item = getItem();
    item.reactable.tags = [{ name: 'discuss' }];

    const { getByText } = render(<ItemListItem item={item} />);

    getByText('#discuss');

    expect(getByText('#discuss').closest('a').getAttribute('href')).toBe(
      '/t/discuss',
    );
  });

  it('renders user information', () => {
    const { getByText } = render(<ItemListItem item={getItem()} />);

    getByText(/Bob/i);

    expect(getByText(/Bob/i).closest('a').getAttribute('href')).toBe('/bob');
  });
});
