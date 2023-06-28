import { h } from 'preact';
import { withKnobs, object, text, boolean } from '@storybook/addon-knobs';
import { action } from '@storybook/addon-actions';
import { Article } from '..';
import {
  podcastArticle,
  podcastEpisodeArticle,
  assetPath,
} from '../__tests__/utilities/articleUtilities';

import '../../../assets/stylesheets/articles.scss';

const ICONS = {
  COMMENTS_ICON: assetPath('comments-bubble.png'),
  VIDEO_ICON: assetPath('video-camera.svg'),
};

const commonProps = {
  bookmarkClick: action('Saved/unsaved article'),
};

export default {
  title: 'App Components/Article/Podcast',
  decorators: [withKnobs],
};

export const Podcast = () => (
  <Article
    {...commonProps}
    commentsIcon={text('commentsIcon', ICONS.COMMENTS_ICON)}
    videoIcon={text('videoIcon', ICONS.VIDEO_ICON)}
    isBookmarked={boolean('isBookmarked', false)}
    article={object('article', podcastArticle)}
    currentTag={text('currentTag')}
  />
);

Podcast.storyName = 'podcast';

export const PodcastEpisode = () => (
  <Article
    {...commonProps}
    commentsIcon={text('commentsIcon', ICONS.COMMENTS_ICON)}
    videoIcon={text('videoIcon', ICONS.VIDEO_ICON)}
    isBookmarked={boolean('isBookmarked', false)}
    article={object('article', podcastEpisodeArticle)}
    currentTag={text('currentTag')}
  />
);

PodcastEpisode.storyName = 'podcast episode';
