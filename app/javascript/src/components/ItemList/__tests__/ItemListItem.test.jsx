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
    item.reactable.reading_time = 0.5;
    const wrapper = shallow(<ItemListItem item={item} />);
    expect(wrapper.find('.item-user').text()).toContain('1 min read');
  });

  it('renders with readingtime of 1 min if reading time is null.', () => {
    item.reactable.reading_time = null;
    const wrapper = shallow(<ItemListItem item={item} />);
    expect(wrapper.find('.item-user').text()).toContain('1 min read');
  });

  it('renders correct readingtime.', () => {
    item.reactable.reading_time = 10;
    const wrapper = shallow(<ItemListItem item={item} />);
    expect(wrapper.find('.item-user').text()).toContain('10 min read');
  });

  it('renders without any tags if the tags array is empty.', () => {
    item.reactable.tags = [];
    const wrapper = shallow(<ItemListItem item={item} />);
    expect(wrapper.find('.item-tags').exists()).toEqual(false);
  });

  it('renders tags with links if present.', () => {
    item.reactable.tags = [{ name: 'discuss' }];
    const wrapper = shallow(<ItemListItem item={item} />);
    expect(wrapper.find('.item-tag')[0].attributes.href).toEqual('/t/discuss');
    expect(wrapper.find('.item-tag').text()).toContain('discuss');
  });

  it('renders user information', () => {
    const wrapper = shallow(<ItemListItem item={item} />);
    expect(wrapper.find('.item-user')[0].attributes.href).toEqual('/bob');
    expect(wrapper.find('.item-user').text()).toContain('Bob');
  });
});
