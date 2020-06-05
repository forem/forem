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
    expect(getByText(/Title/i)).toBeTruthy();
  });

  it('renders the path', () => {
    const { getByText } = render(<ItemListItem item={item} />);
    expect(getByText(/Title/i).closest('a').getAttribute("href")).toBe("/article");
  });

  it('renders a published date', () => {
    const { getByText } = render(<ItemListItem item={item} />);
    expect(getByText(/Jun 29/i)).toBeTruthy();
  });

  it('renders a profile_image', () => {
    const { getByAltText } = render(<ItemListItem item={item} />);
    expect(getByAltText(/Profile Pic/i).getAttribute("src")).toBe("https://dummyimage.com/90x90");
  });

  it('renders with readingtime of 1 min if reading time is less than 1 min.', () => {
    item.reactable.reading_time = 0.5;
    const { getByText } = render(<ItemListItem item={item} />);
    expect(getByText(/1 min read/i)).toBeTruthy();
  });

  it('renders with readingtime of 1 min if reading time is null.', () => {
    item.reactable.reading_time = null;
    const { getByText } = render(<ItemListItem item={item} />);
    expect(getByText(/1 min read/i)).toBeTruthy();
  });

  it('renders correct readingtime.', () => {
    item.reactable.reading_time = 10;
    const { getByText } = render(<ItemListItem item={item} />);
    expect(getByText(/10 min read/i)).toBeTruthy();
  });

  it('renders without any tags if the tags array is empty.', () => {
    item.reactable.tags = [];
    const { queryByTestId } = render(<ItemListItem item={item} />);
    expect(queryByTestId('item-tags')).toBeNull();
  });

  it('renders tags with links if present.', () => {
    item.reactable.tags = [{ name: 'discuss' }];
    const { queryByTestId, getByText } = render(<ItemListItem item={item} />);
    expect(getByText('#discuss')).toBeTruthy();
    expect(getByText('#discuss').closest('a').getAttribute("href")).toBe("/t/discuss");
  });

  it('renders user information', () => {
    const { getByText } = render(<ItemListItem item={item} />);
    expect(getByText(/Bob/i)).toBeTruthy();
    expect(getByText(/Bob/i).closest('a').getAttribute("href")).toBe("/bob");
  });
});
