import { h } from 'preact';
import { withKnobs, object, text, boolean } from '@storybook/addon-knobs';
import { action } from '@storybook/addon-actions';
import { Article } from '..';
import {
  videoArticle,
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
  title: 'App Components/Article/Video',
  decorators: [withKnobs],
};

export const Default = () => (
  <Article
    {...commonProps}
    reactionsIcon={text('reactionsIcon', ICONS.REACTIONS_ICON)}
    commentsIcon={text('commentsIcon', ICONS.COMMENTS_ICON)}
    videoIcon={text('videoIcon', ICONS.VIDEO_ICON)}
    isBookmarked={boolean('isBookmarked', false)}
    article={object('article', videoArticle)}
    currentTag={text('currentTag', 'javascript')}
  />
);

Default.story = { name: 'default' };

export const VideoArticleWithFlareTag = () => (
  <Article
    {...commonProps}
    reactionsIcon={text('reactionsIcon', ICONS.REACTIONS_ICON)}
    commentsIcon={text('commentsIcon', ICONS.COMMENTS_ICON)}
    videoIcon={text('videoIcon', ICONS.VIDEO_ICON)}
    isBookmarked={boolean('isBookmarked', false)}
    article={object('article', videoArticle)}
    currentTag={text('currentTag')}
  />
);

VideoArticleWithFlareTag.story = { name: 'video with flare tag' };
