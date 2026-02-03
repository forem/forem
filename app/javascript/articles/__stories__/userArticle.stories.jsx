import { h } from 'preact';
import { action } from '@storybook/addon-actions';
import { Article } from '..';
import {
  assetPath,
  userArticle,
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
  title: 'App Components/Article/User',
  component: Article,
  argTypes: {
    commentsIcon: {
      control: { type: 'text' },
    },
    videoIcon: {
      control: { type: 'text' },
    },
    article: {
      control: { type: 'object' },
    },
  },
  args: {
    commentsIcon: ICONS.COMMENTS_ICON,
    videoIcon: ICONS.VIDEO_ICON,
    article: userArticle,
  },
};

export const UserArticle = (args) => (
  <Article
    {...commonProps}
    commentsIcon={args.commentsIcon}
    videoIcon={args.videoIcon}
    article={args.article}
  />
);

UserArticle.storyName = 'default';
