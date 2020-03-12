import { h } from 'preact';
import { storiesOf } from '@storybook/react';
import { withKnobs, object, text, boolean } from '@storybook/addon-knobs/react';
import { action } from '@storybook/addon-actions';
import {
  featuredArticle,
  assetPath,
} from '../__tests__/utilities/articleUtilities';
import { FeaturedArticle } from '..';
import { articleDecorator } from './articleDecorator';

import '../../../assets/stylesheets/articles.scss';

const ICONS = {
  REACTIONS_ICON: assetPath('reactions-stack.png'),
  COMMENTS_ICON: assetPath('comments-bubble.png'),
  VIDEO_ICON: assetPath('video-camera.svg'),
};

const commonProps = {
  bookmarkClick: action('Saved/unsaved article'),
};

storiesOf('App Components/Article/Featured', module)
  .addDecorator(withKnobs)
  .addDecorator(articleDecorator)
  .add('Default', () => (
    <FeaturedArticle
      {...commonProps}
      reactionsIcon={text('reactionsIcon', ICONS.REACTIONS_ICON)}
      commentsIcon={text('commentsIcon', ICONS.COMMENTS_ICON)}
      videoIcon={text('videoIcon', ICONS.VIDEO_ICON)}
      article={object('article', featuredArticle)}
    />
  ))
  .add('Is on Reading List', () => (
    <FeaturedArticle
      {...commonProps}
      reactionsIcon={text('reactionsIcon', ICONS.REACTIONS_ICON)}
      commentsIcon={text('commentsIcon', ICONS.COMMENTS_ICON)}
      isBookmarked={boolean('isBookmarked', true)}
      article={object('article', featuredArticle)}
    />
  ));
