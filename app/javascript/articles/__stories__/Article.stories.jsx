import { h } from 'preact';
import { storiesOf } from '@storybook/react';
import faker from 'faker';
import { Article, PodcastArticle } from '..';
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
  tag_list: [
    {
      id: faker.random.number(),
      name: 'javascript',
      hotness_score: 99,
      points: 23,
      bg_color_hex: '#ffff00',
      text_color_hex: '#000000',
    },
    {
      id: faker.random.number(),
      name: 'ruby',
      hotness_score: 12,
      points: 43,
      bg_color_hex: '##ff0000',
      text_color_hex: '#ffffff',
    },
    {
      id: faker.random.number(),
      name: 'go',
      hotness_score: 13,
      points: 3,
      bg_color_hex: '#000000',
      text_color_hex: '#ffffff',
    },
  ],
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
  positive_reactions_count: 125,
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
  .addDecorator(articleDecorator)
  .add('Default', () => <Article article={article} currentTag="javascript" />)
  .add('With Organization', () => (
    <Article article={articleWithOrganization} currentTag="javascript" />
  ))
  .add('Wth Flare Tag', () => <Article article={article} />)
  .add('Wth Snippet Result', () => (
    <Article article={articleWithSnippetResult} />
  ))
  .add('Wth Reading Time', () => (
    <Article article={articleWithReadingTimeGreaterThan1} />
  ))
  .add('Wth Reactions', () => <Article article={articleWithReactions} />);

storiesOf('Components/Articles/Video', module)
  .addDecorator(articleDecorator)
  .add('Default', () => (
    <Article article={videoArticle} currentTag="javascript" />
  ))
  .add('Video Article and Flare Tag', () => <Article article={videoArticle} />);

storiesOf('Components/Articles/Podcast', module)
  .addDecorator(articleDecorator)
  .add('Default', () => <PodcastArticle article={podcastArticle} />);
