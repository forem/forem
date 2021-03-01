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
  REACTIONS_ICON: assetPath('reactions-stack.png'),
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
    reactionsIcon={text('reactionsIcon', ICONS.REACTIONS_ICON)}
    commentsIcon={text('commentsIcon', ICONS.COMMENTS_ICON)}
    videoIcon={text('videoIcon', ICONS.VIDEO_ICON)}
    isBookmarked={boolean('isBookmarked', false)}
    article={object('article', podcastArticle)}
    currentTag={text('currentTag')}
  />
);

Podcast.story = {
  name: 'podcast',
};

export const PodcastEpisode = () => (
  <Article
    {...commonProps}
    reactionsIcon={text('reactionsIcon', ICONS.REACTIONS_ICON)}
    commentsIcon={text('commentsIcon', ICONS.COMMENTS_ICON)}
    videoIcon={text('videoIcon', ICONS.VIDEO_ICON)}
    isBookmarked={boolean('isBookmarked', false)}
    article={object('article', podcastEpisodeArticle)}
    currentTag={text('currentTag')}
  />
);

PodcastEpisode.story = { name: 'podcast episode' };
