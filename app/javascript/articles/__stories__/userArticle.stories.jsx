import { h } from 'preact';
import { action } from '@storybook/addon-actions';
import { withKnobs, object, text } from '@storybook/addon-knobs';
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
  decorators: [withKnobs],
};

export const UserArticle = () => (
  <Article
    {...commonProps}
    commentsIcon={text('commentsIcon', ICONS.COMMENTS_ICON)}
    videoIcon={text('videoIcon', ICONS.VIDEO_ICON)}
    article={object('article', userArticle)}
  />
);

UserArticle.storyName = 'default';
