import { h } from 'preact';

import { PodcastEpisode } from '../PodcastEpisode';
import { podcastArticle } from '../../articles/__tests__/utilities/articleUtilities';

import '../../../assets/stylesheets/articles.scss';

export default { title: 'App Components/Podcasts/Episode' };

export const Standard = () => <PodcastEpisode episode={podcastArticle} />;

Standard.storyName = 'standard';
