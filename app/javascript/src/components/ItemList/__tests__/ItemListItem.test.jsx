import { h } from 'preact';
import render from 'preact-render-to-json';
import { ItemListItem } from '../ItemListItem';

describe('<ItemListItem />', () => {
  it('renders properly with a history item', () => {
    const item = {
      article_path: '/article',
      article_title: 'Title',
      article_user: {
        username: 'bob',
        profile_image_90: 'https://dummyimage.com/90x90',
        name: 'Bob',
      },
      article_reading_time: '1 min read',
      readable_visited_at: 'Jun 29',
      article_tags: ['discuss'],
    };
    const tree = render(<ItemListItem item={item} />);
    expect(tree).toMatchSnapshot();
  });

  it('renders properly with a readinglist item', () => {
    const item = {
      searchable_reactable_path: '/article',
      searchable_reactable_title: 'Title',
      reactable_user: {
        username: 'bob',
        profile_image_90: 'https://dummyimage.com/90x90',
        name: 'Bob',
      },
      reading_time: '1 min read',
      reactable_published_date: 'Jun 29',
      reactable_tags: ['discuss'],
    };
    const tree = render(<ItemListItem item={item} />);
    expect(tree).toMatchSnapshot();
  });
});
