import { h } from 'preact';
import render from 'preact-render-to-json';
import { shallow } from 'preact-render-spy';
import { ItemListItem } from '../ItemListItem';

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
