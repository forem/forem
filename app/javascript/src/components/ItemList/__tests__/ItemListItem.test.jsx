import { h } from 'preact';
import { render } from 'preact-render-to-string';
import { shallow } from 'preact-render-spy';
import { ItemListItem } from '../ItemListItem';

const historyItem = {
  article_path: '/article',
  article_title: 'Title',
  article_user: {
    username: 'bob',
    profile_image_90: 'https://dummyimage.com/90x90',
    name: 'Bob',
  },
  article_reading_time: 1,
  readable_visited_at: 'Jun 29',
  article_tags: ['discuss'],
};

const item = {
  searchable_reactable_path: '/article',
  searchable_reactable_title: 'Title',
  reactable_user: {
    username: 'bob',
    profile_image_90: 'https://dummyimage.com/90x90',
    name: 'Bob',
  },
  reading_time: 1,
  reactable_published_date: 'Jun 29',
  reactable_tags: ['discuss'],
};

describe('<ItemListItem />', () => {
  it('renders properly with a history item', () => {
    const tree = render(<ItemListItem item={historyItem} />);
    expect(tree).toMatchSnapshot();
  });

  it('renders properly with a readinglist item', () => {
    const tree = render(<ItemListItem item={item} />);
    expect(tree).toMatchSnapshot();
  });

  it('renders with readingtime of 1 min if reading time is less than 1 min.', () => {
    const wrapper = shallow(
      <ItemListItem item={{ ...item, reading_time: 0.5 }} />,
    );
    expect(wrapper.find('.item-user').text()).toContain('1 min read');
  });

  it('renders with readingtime of 1 min if reading time is null.', () => {
    const wrapper = shallow(
      <ItemListItem item={{ ...item, reading_time: null }} />,
    );
    expect(wrapper.find('.item-user').text()).toContain('1 min read');
  });

  it('renders without any tags if the tags array is empty.', () => {
    const wrapper = shallow(
      <ItemListItem item={{ ...item, reactable_tags: [] }} />,
    );
    expect(wrapper.find('.item-user').text()).toContain('1 min read');
  });
});
