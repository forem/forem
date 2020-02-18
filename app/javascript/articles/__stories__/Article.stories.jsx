import { h } from 'preact';
import { storiesOf } from '@storybook/react';
import faker from 'faker';
import { withKnobs, object, text, boolean } from '@storybook/addon-knobs/react';
import { Article } from '..';
import { articleDecorator } from './articleDecorator';

import '../../../assets/stylesheets/articles.scss';

const title = faker.random.words(2);

const getName = () => `${faker.name.firstName()} ${faker.name.lastName()}`;

const publishDate = new Date();
const article = {
  id: faker.random.number(),
  title,
  path: '/some-post/path',
  type_of: '',
  class_name: 'Article',
  flare_tag: {
    id: faker.random.number(),
    name: 'javascript',
    hotness_score: 99,
    points: 23,
    bg_color_hex: '#000000',
    text_color_hex: '#ffffff',
  },
  tag_list: ['javascript', 'ruby', 'go'],
  cached_tag_list_array: [],
  user_id: faker.random.number(),
  user: {
    username: faker.internet.userName(),
    name: getName(),
    // We have 40 fake O'Reilly images to work with
    profile_image_90: `/images/10.png`,
  },
  published_at_int: publishDate.getTime(),
  published_timestamp: publishDate.toUTCString(),
  readable_publish_date: new Intl.DateTimeFormat('en-US', {
    month: 'long',
    day: 'numeric',
  }).format(publishDate),
};

const articleWithOrganization = {
  ...article,
  organization: {
    id: faker.random.number(),
    name: faker.random.words(2),
    slug: faker.helpers.slugify(faker.random.words(2)),
    profile_image_90: `/images/30.png`,
  },
};

const articleWithSnippetResult = {
  ...article,
  _snippetResult: {
    body_text: {
      matchLevel: 'full',
      value: faker.random.words(15),
    },
    comments_blob: {
      matchLevel: 'none',
      value: faker.random.words(15),
    },
  },
};

const articleWithReactions = {
  ...article,
  positive_reactions_count: faker.random.number({ min: 1, max: 500 }),
};

const articleWithComments = {
  ...article,
  positive_reactions_count: faker.random.number({ min: 1, max: 500 }),
  comments_count: faker.random.number({ min: 1, max: 500 }),
};

const articleWithReadingTimeGreaterThan1 = {
  ...article,
  reading_time: 8,
};

const videoArticle = {
  ...article,
  cloudinary_video_url: '/images/onboarding-background.png',
  video_duration_in_minutes: 10,
};

const podcastArticle = {
  ...article,
  type_of: 'podcast_episodes',
  podcast: {
    slug: title.replace(/\s+/, '-').toLowerCase(),
    title: faker.random.words(2),
    image_url: `/images/16.png`,
  },
};

const podcastEpisodeArticle = {
  ...article,
  class_name: 'PodcastEpisode',
};

const name = getName();
const userArticle = {
  id: faker.random.number(),
  title: name,
  user_id: faker.random.number(),
  class_name: 'User',
  user: {
    username: name.replace(/\s+/, '.').toLowerCase(),
    name,
    // We have 40 fake O'Reilly images to work with
    profile_image_90: `/images/3.png`,
  },
};

storiesOf('Components/Articles/Standard', module)
  .addDecorator(withKnobs)
  .addDecorator(articleDecorator)
  .add('Default', () => (
    <Article
      isBookmarked={boolean('isBookmarked', false)}
      article={object('article', article)}
      currentTag={text('currentTag', 'javascript')}
    />
  ))
  .add('With Organization', () => (
    <Article
      isBookmarked={boolean('isBookmarked', false)}
      article={object('article', articleWithOrganization)}
      currentTag={text('currentTag', 'javascript')}
    />
  ))
  .add('Wth Flare Tag', () => (
    <Article
      isBookmarked={boolean('isBookmarked', false)}
      article={object('article', article)}
      currentTag={text('currentTag')}
    />
  ))
  .add('Wth Snippet Result', () => (
    <Article
      isBookmarked={boolean('isBookmarked', false)}
      article={object('article', articleWithSnippetResult)}
      currentTag={text('currentTag')}
    />
  ))
  .add('Wth Reading Time', () => (
    <Article
      isBookmarked={boolean('isBookmarked', false)}
      article={object('article', articleWithReadingTimeGreaterThan1)}
      currentTag={text('currentTag')}
    />
  ))
  .add('Wth Reactions', () => (
    <Article
      isBookmarked={boolean('isBookmarked', false)}
      article={object('article', articleWithReactions)}
      currentTag={text('currentTag')}
    />
  ))
  .add('With Comments', () => (
    <Article
      isBookmarked={boolean('isBookmarked', false)}
      article={object('article', articleWithComments)}
      currentTag={text('currentTag')}
    />
  ))
  .add('Is on Reading List', () => (
    <Article
      isBookmarked={boolean('isBookmarked', true)}
      article={object('article', articleWithComments)}
      currentTag={text('currentTag')}
    />
  ));

storiesOf('Components/Articles/Video', module)
  .addDecorator(withKnobs)
  .addDecorator(articleDecorator)
  .add('Default', () => (
    <Article
      isBookmarked={boolean('isBookmarked', false)}
      article={videoArticle}
      currentTag={text('currentTag', 'javascript')}
    />
  ))
  .add('Video Article and Flare Tag', () => (
    <Article
      isBookmarked={boolean('isBookmarked', false)}
      article={object('article', videoArticle)}
      currentTag={text('currentTag')}
    />
  ));

storiesOf('Components/Articles/Podcast', module)
  .addDecorator(withKnobs)
  .addDecorator(articleDecorator)
  .add('Default', () => (
    <Article
      isBookmarked={boolean('isBookmarked', false)}
      article={object('article', podcastArticle)}
      currentTag={text('currentTag')}
    />
  ))
  .add('Podcast Episode', () => (
    <Article
      isBookmarked={boolean('isBookmarked', false)}
      article={object('article', podcastEpisodeArticle)}
      currentTag={text('currentTag')}
    />
  ));

storiesOf('Components/Articles/User', module)
  .addDecorator(withKnobs)
  .addDecorator(articleDecorator)
  .add('Default', () => <Article article={object('article', userArticle)} />);
