import { h } from 'preact';
import render from 'preact-render-to-json';
import { deep } from 'preact-render-spy';
import fetch from 'jest-fetch-mock';
import Article from '../article';

global.fetch = fetch;

function flushPromises() {
  return new Promise(resolve => setImmediate(resolve));
}

const sampleResponse = JSON.stringify({
  current_user: { id: 10000 },
  article_reaction_counts: [
    { category: 'like', count: 150 },
    { category: 'readinglist', count: 17 },
    { category: 'unicorn', count: 48 },
  ],
  reactions: [
    {
      id: 10000,
      user_id: 10000,
      reactable_id: 10000,
      reactable_type: 'Article',
      category: 'like',
      points: 1.0,
      created_at: '2018-10-30T20:34:01.503Z',
      updated_at: '2018-10-30T20:34:01.503Z',
    },
  ],
});

const userArticle = {
  type_of: 'article',
  path: '/princesscarolyn/your-approval-means-nothing-to-me-42640',
};

const getArticle = () => <Article resource={userArticle} />;

describe('<Article />', () => {
  it('should load article', async () => {
    const tree = render(getArticle());
    await flushPromises();
    expect(tree).toMatchSnapshot();
  });

  it('should have the proper elements, attributes and values', async () => {
    await fetch.mockResponseOnce(sampleResponse);
    const context = deep(getArticle(), { depth: 2 });
    await flushPromises();

    // checks that article details are placed at their appropriate elements
    expect(context.find('.activechatchannel__activeArticle').exists()).toEqual(
      true,
    );
    expect(
      context.find('iframe').exists(),
    ).toEqual(true);
  });
});
