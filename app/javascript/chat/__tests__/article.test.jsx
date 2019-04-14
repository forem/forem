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
  id: '42640',
  cover_image: 'princess_carolyn_is_perfect.png',
  path: '/princesscarolyn/your-approval-means-nothing-to-me-42640',
  title: 'Your Approval Means Nothing to Me',
  readable_publish_date: 'July 30, 2014',
  body_html:
    "That woman can knock a drink back like a Kennedy at a wake for another Kennedy, but I'll be damned if she doesn't get s*** done!",
  user: {
    id: '00001',
    username: 'princesscarolyn',
    name: 'Princess Carolyn',
    profile_image_90: '/princesscarolyn.png',
  },
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
      context.find('.activechatchannel__activeArticleDetails').exists(),
    ).toEqual(true);
    expect(
      context
        .find('.activechatchannel__activeArticleDetails')
        .childAt(0)
        .attr('href'),
    ).toEqual(userArticle.path);
    expect(
      context.find('.activechatchannel__activeArticleDetailsPath').text(),
    ).toEqual(userArticle.path);
    expect(
      context
        .find('.title')
        .childAt(0)
        .text(),
    ).toEqual(userArticle.title);
    expect(context.find('.author').attr('href')).toEqual(
      `/${userArticle.user.username}`,
    );
    expect(context.find('.profile-pic').attr('src')).toEqual(
      userArticle.user.profile_image_90,
    );
    expect(context.find('.author').text()).toEqual(
      `${userArticle.user.name}  | ${userArticle.readable_publish_date}`,
    );
    expect(context.find('.published-at').text()).toEqual(
      ` | ${userArticle.readable_publish_date}`,
    );
    expect(
      context
        .find('.body')
        .childAt(0)
        .attr('dangerouslySetInnerHTML'),
    ).toEqual({ __html: userArticle.body_html });

    // checks reaction
    expect(
      context.find('.activechatchannel__activeArticleActions').exists(),
    ).toEqual(true);
    expect(context.find('.heart-reaction-button').exists()).toEqual(true);
    expect(context.find('.unicorn-reaction-button').exists()).toEqual(true);
    expect(context.find('.readinglist-reaction-button').exists()).toEqual(true);

    // checks that only heart class has active
    expect(context.find('.heart-reaction-button').attr('className')).toEqual(
      'heart-reaction-button active',
    );
    expect(context.find('.unicorn-reaction-button').attr('className')).toEqual(
      'unicorn-reaction-button ',
    );
    expect(
      context.find('.readinglist-reaction-button').attr('className'),
    ).toEqual('readinglist-reaction-button ');
  });
});
