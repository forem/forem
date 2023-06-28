import { h } from 'preact';

import '../../../assets/stylesheets/articles.scss';
import { TodaysPodcasts } from '../TodaysPodcasts';
import { PodcastEpisode } from '../PodcastEpisode';
import { podcastArticle } from '../../articles/__tests__/utilities/articleUtilities';

const episodes = [
  podcastArticle,
  podcastArticle,
  podcastArticle,
  podcastArticle,
  podcastArticle,
];

export default {
  title: `App Components/Podcasts/Today's Episodes`,
};

export const Standard = () => (
  <TodaysPodcasts>
    {episodes.map((episode) => (
      <PodcastEpisode key={episode.id} episode={episode} />
    ))}
  </TodaysPodcasts>
);

Standard.storyName = 'standard';
