import { h } from 'preact';
import { action } from '@storybook/addon-actions';
import { Article } from '..';
import {
  videoArticle,
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
  title: 'App Components/Article/Video',
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
    article: videoArticle,
    currentTag: 'javascript',
  },
};

export const Default = (args) => (
  <Article
    {...commonProps}
    commentsIcon={args.commentsIcon}
    videoIcon={args.videoIcon}
    isBookmarked={args.isBookmarked}
    article={args.article}
    currentTag={args.currentTag}
  />
);

Default.storyName = 'default';

export const VideoArticleWithFlareTag = (args) => (
  <Article
    {...commonProps}
    commentsIcon={args.commentsIcon}
    videoIcon={args.videoIcon}
    isBookmarked={args.isBookmarked}
    article={args.article}
    currentTag={args.currentTag}
  />
);

VideoArticleWithFlareTag.storyName = 'video with flare tag';
