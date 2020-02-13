import { h } from 'preact';
import { storiesOf } from '@storybook/react';
import faker from 'faker';
import { PodcastArticle } from '..';
import '../../../assets/stylesheets/articles.scss';
import { articleDecorator } from './articleDecorator';

const title = faker.random.words(2);

const article = {
  id: 1,
  title,
  type_of: 'podcast_episodes',
  path: '/some-post/path',
  podcast: {
    slug: title.replace(/\s+/, '-').toLowerCase(),
    title: faker.random.words(2),
    image_url: `/images/${Math.floor(Math.random() * 40)}.png`,
  },
};

storiesOf('Components/Articles/Podcast', module)
  .addDecorator(articleDecorator)
  .add('Default', () => <PodcastArticle article={article} />);
