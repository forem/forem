import { h } from 'preact';

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

export default {
  title: `App Components/Podcasts/Today's Episodes`,
  decorators: [articleDecorator],
};

export const Standard = () => (
  <TodaysPodcasts>
    {episodes.map(episode => (
      <PodcastEpisode episode={episode} />
    ))}
  </TodaysPodcasts>
);

Standard.story = { name: 'standard' };
