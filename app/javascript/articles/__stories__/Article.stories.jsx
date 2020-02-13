import { h } from 'preact';
import { storiesOf } from '@storybook/react';
import faker from 'faker';
import { withKnobs, object, text, boolean } from '@storybook/addon-knobs/react';
import { Article } from '..';
import { articleDecorator } from './articleDecorator';

import '../../../assets/stylesheets/articles.scss';

const title = faker.random.words(2);

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
  user_id: 1,
  user: {
    username: faker.random.word(),
    name: faker.random.words(2),
    // We have 40 fake O'Reilly images to work with
    profile_image_90: `/images/${Math.floor(Math.random() * 40)}.png`,
  },
};

const articleWithOrganization = {
  ...article,
  organization: {
    id: faker.random.number(),
    name: faker.random.words(2),
    slug: faker.helpers.slugify(faker.random.words(2)),
    profile_image_90: `/images/${Math.floor(Math.random() * 40)}.png`,
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
  user: {
    ...article.user,
    profile_image_90: `/images/${Math.floor(Math.random() * 40)}.png`,
  },
};

const articleWithComments = {
  ...article,
  positive_reactions_count: faker.random.number({ min: 1, max: 500 }),
  comments_count: faker.random.number({ min: 1, max: 500 }),
  user: {
    ...article.user,
    profile_image_90: `/images/${Math.floor(Math.random() * 40)}.png`,
  },
};

const articleWithReadingTimeGreaterThan1 = {
  ...article,
  user: {
    ...article.user,
    profile_image_90: `/images/${Math.floor(Math.random() * 40)}.png`,
  },
  reading_time: 8,
};

const videoArticle = {
  ...article,
  cloudinary_video_url: '/images/onboarding-background.png',
  video_duration_in_minutes: 10,
  user: {
    ...article.user,
    profile_image_90: `/images/${Math.floor(Math.random() * 40)}.png`,
  },
};

const podcastArticle = {
  ...article,
  podcast: {
    slug: title.replace(/\s+/, '-').toLowerCase(),
    title: faker.random.words(2),
    image_url: `/images/${Math.floor(Math.random() * 40)}.png`,
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
  ));
