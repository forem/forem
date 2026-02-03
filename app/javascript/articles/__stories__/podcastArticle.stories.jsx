import { h } from 'preact';
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
  component: Article,
  argTypes: {
    commentsIcon: {
      control: { type: 'text' },
    },
    videoIcon: {
      control: { type: 'text' },
    },
    isBookmarked: {
      control: { type: 'boolean' },
    },
    article: {
      control: { type: 'object' },
    },
    currentTag: {
      control: { type: 'text' },
    },
  },
  args: {
    commentsIcon: ICONS.COMMENTS_ICON,
    videoIcon: ICONS.VIDEO_ICON,
    isBookmarked: false,
    article: podcastArticle,
    currentTag: '',
  },
};

export const Podcast = (args) => (
  <Article
    {...commonProps}
    commentsIcon={args.commentsIcon}
    videoIcon={args.videoIcon}
    isBookmarked={args.isBookmarked}
    article={args.article}
    currentTag={args.currentTag}
  />
);

Podcast.storyName = 'podcast';

export const PodcastEpisode = (args) => (
  <Article
    {...commonProps}
    commentsIcon={args.commentsIcon}
    videoIcon={args.videoIcon}
    isBookmarked={args.isBookmarked}
    article={podcastEpisodeArticle}
    currentTag={args.currentTag}
  />
);

PodcastEpisode.storyName = 'podcast episode';
