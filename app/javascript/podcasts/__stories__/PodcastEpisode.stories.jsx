import { h } from 'preact';
import { storiesOf } from '@storybook/react';
import { PodcastEpisode } from '../PodcastEpisode';
import { podcastArticle } from '../../articles/__tests__/utilities/articleUtilities';

import '../../../assets/stylesheets/articles.scss';

storiesOf(`Components/Podcasts/Episode`, module).add('Standard', () => (
  <PodcastEpisode episode={podcastArticle} />
));
