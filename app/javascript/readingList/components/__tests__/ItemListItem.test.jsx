import { h } from 'preact';
import { render } from '@testing-library/preact';
import { ItemListItem } from '../ItemListItem';
import '../../../../assets/javascripts/lib/xss';

const item = {
  reactable: {
    path: '/article',
    title: 'Title',
    published_date_string: 'Jun 29',
    reading_time: 1,
    user: {
      username: 'bob',
      profile_image_90: 'https://dummyimage.com/90x90',
      name: 'Bob',
    },
    tags: [{ name: 'discuss' }],
  },
};

describe('<ItemListItem />', () => {
  it('renders the title', () => {
    const { getByText } = render(<ItemListItem item={item} />);
    getByText(/Title/i);
  });

  it('renders the path', () => {
    const { getByText } = render(<ItemListItem item={item} />);
    expect(getByText(/Title/i).closest('a').getAttribute("href")).toBe("/article");
  });

  it('renders a published date', () => {
    const { getByText } = render(<ItemListItem item={item} />);
    getByText(/Jun 29/i);
  });

  it('renders a profile_image', () => {
    const { getByAltText } = render(<ItemListItem item={item} />);
    expect(getByAltText(/Profile Pic/i).getAttribute("src")).toBe("https://dummyimage.com/90x90");
  });

  it('renders with readingtime of 1 min if reading time is less than 1 min.', () => {
    item.reactable.reading_time = 0.5;
    const { getByText } = render(<ItemListItem item={item} />);
    getByText(/1 min read/i);
  });

  it('renders with readingtime of 1 min if reading time is null.', () => {
    item.reactable.reading_time = null;
    const { getByText } = render(<ItemListItem item={item} />);
    getByText(/1 min read/i);
  });

  it('renders correct readingtime.', () => {
    item.reactable.reading_time = 10;
    const { getByText } = render(<ItemListItem item={item} />);
    getByText(/10 min read/i);
  });

  it('renders without any tags if the tags array is empty.', () => {
    item.reactable.tags = [];
    const { queryByTestId } = render(<ItemListItem item={item} />);
    expect(queryByTestId('item-tags')).toBeNull();
  });

  it('renders tags with links if present.', () => {
    item.reactable.tags = [{ name: 'discuss' }];
    const { queryByTestId, getByText } = render(<ItemListItem item={item} />);
    getByText('#discuss');
    expect(getByText('#discuss').closest('a').getAttribute("href")).toBe("/t/discuss");
  });

  it('renders user information', () => {
    const { getByText } = render(<ItemListItem item={item} />);
    getByText(/Bob/i);
    expect(getByText(/Bob/i).closest('a').getAttribute("href")).toBe("/bob");
  });
});
