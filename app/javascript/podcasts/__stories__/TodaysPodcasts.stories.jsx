import { h } from 'preact';
import { storiesOf } from '@storybook/react';

import '../../../assets/stylesheets/articles.scss';
import { TodaysPodcasts } from '../TodaysPodcasts';
import { PodcastEpisode } from '../PodcastEpisode';
import { podcastArticle } from '../../articles/__tests__/utilities/articleUtilities';
import { articleDecorator } from '../../articles/__stories__/articleDecorator';

const episodes = [
  podcastArticle,
  podcastArticle,
  podcastArticle,
  podcastArticle,
  podcastArticle,
];

storiesOf(`App Components/Podcasts/Today's Episodes`, module)
  .addDecorator(articleDecorator)
  .add('Standard', () => (
    <TodaysPodcasts>
      {episodes.map(episode => (
        <PodcastEpisode episode={episode} />
      ))}
    </TodaysPodcasts>
  ));
