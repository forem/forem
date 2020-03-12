import { h } from 'preact';
import { storiesOf } from '@storybook/react';
import { withKnobs, object, text, boolean } from '@storybook/addon-knobs/react';
import { action } from '@storybook/addon-actions';
import { Article } from '..';
import {
  article,
  articleWithOrganization,
  articleWithSnippetResult,
  articleWithReadingTimeGreaterThan1,
  articleWithReactions,
  videoArticle,
  articleWithComments,
  podcastArticle,
  podcastEpisodeArticle,
  userArticle,
  assetPath,
} from '../__tests__/utilities/articleUtilities';
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

storiesOf('App Components/Article/Standard', module)
  .addDecorator(withKnobs)
  .addDecorator(articleDecorator)
  .add('Default', () => (
    <Article
      {...commonProps}
      reactionsIcon={text('reactionsIcon', ICONS.REACTIONS_ICON)}
      commentsIcon={text('commentsIcon', ICONS.COMMENTS_ICON)}
      videoIcon={text('videoIcon', ICONS.VIDEO_ICON)}
      isBookmarked={boolean('isBookmarked', false)}
      article={object('article', article)}
      currentTag={text('currentTag', 'javascript')}
    />
  ))
  .add('With Organization', () => (
    <Article
      {...commonProps}
      reactionsIcon={text('reactionsIcon', ICONS.REACTIONS_ICON)}
      commentsIcon={text('commentsIcon', ICONS.COMMENTS_ICON)}
      videoIcon={text('videoIcon', ICONS.VIDEO_ICON)}
      isBookmarked={boolean('isBookmarked', false)}
      article={object('article', articleWithOrganization)}
      currentTag={text('currentTag', 'javascript')}
    />
  ))
  .add('Wth Flare Tag', () => (
    <Article
      {...commonProps}
      reactionsIcon={text('reactionsIcon', ICONS.REACTIONS_ICON)}
      commentsIcon={text('commentsIcon', ICONS.COMMENTS_ICON)}
      videoIcon={text('videoIcon', ICONS.VIDEO_ICON)}
      isBookmarked={boolean('isBookmarked', false)}
      article={object('article', article)}
      currentTag={text('currentTag')}
    />
  ))
  .add('Wth Snippet Result', () => (
    <Article
      {...commonProps}
      reactionsIcon={text('reactionsIcon', ICONS.REACTIONS_ICON)}
      commentsIcon={text('commentsIcon', ICONS.COMMENTS_ICON)}
      videoIcon={text('videoIcon', ICONS.VIDEO_ICON)}
      isBookmarked={boolean('isBookmarked', false)}
      article={object('article', articleWithSnippetResult)}
      currentTag={text('currentTag')}
    />
  ))
  .add('Wth Reading Time', () => (
    <Article
      {...commonProps}
      reactionsIcon={text('reactionsIcon', ICONS.REACTIONS_ICON)}
      commentsIcon={text('commentsIcon', ICONS.COMMENTS_ICON)}
      videoIcon={text('videoIcon', ICONS.VIDEO_ICON)}
      isBookmarked={boolean('isBookmarked', false)}
      article={object('article', articleWithReadingTimeGreaterThan1)}
      currentTag={text('currentTag')}
    />
  ))
  .add('Wth Reactions', () => (
    <Article
      {...commonProps}
      reactionsIcon={text('reactionsIcon', ICONS.REACTIONS_ICON)}
      commentsIcon={text('commentsIcon', ICONS.COMMENTS_ICON)}
      videoIcon={text('videoIcon', ICONS.VIDEO_ICON)}
      isBookmarked={boolean('isBookmarked', false)}
      article={object('article', articleWithReactions)}
      currentTag={text('currentTag')}
    />
  ))
  .add('With Comments', () => (
    <Article
      {...commonProps}
      reactionsIcon={text('reactionsIcon', ICONS.REACTIONS_ICON)}
      commentsIcon={text('commentsIcon', ICONS.COMMENTS_ICON)}
      videoIcon={text('videoIcon', ICONS.VIDEO_ICON)}
      isBookmarked={boolean('isBookmarked', false)}
      article={object('article', articleWithComments)}
      currentTag={text('currentTag')}
    />
  ))
  .add('Is on Reading List', () => (
    <Article
      {...commonProps}
      reactionsIcon={text('reactionsIcon', ICONS.REACTIONS_ICON)}
      commentsIcon={text('commentsIcon', ICONS.COMMENTS_ICON)}
      videoIcon={text('videoIcon', ICONS.VIDEO_ICON)}
      isBookmarked={boolean('isBookmarked', true)}
      article={object('article', articleWithComments)}
      currentTag={text('currentTag')}
    />
  ));

storiesOf('App Components/Article/Video', module)
  .addDecorator(withKnobs)
  .addDecorator(articleDecorator)
  .add('Default', () => (
    <Article
      {...commonProps}
      reactionsIcon={text('reactionsIcon', ICONS.REACTIONS_ICON)}
      commentsIcon={text('commentsIcon', ICONS.COMMENTS_ICON)}
      videoIcon={text('videoIcon', ICONS.VIDEO_ICON)}
      isBookmarked={boolean('isBookmarked', false)}
      article={object('article', videoArticle)}
      currentTag={text('currentTag', 'javascript')}
    />
  ))
  .add('Video Article and Flare Tag', () => (
    <Article
      {...commonProps}
      reactionsIcon={text('reactionsIcon', ICONS.REACTIONS_ICON)}
      commentsIcon={text('commentsIcon', ICONS.COMMENTS_ICON)}
      videoIcon={text('videoIcon', ICONS.VIDEO_ICON)}
      isBookmarked={boolean('isBookmarked', false)}
      article={object('article', videoArticle)}
      currentTag={text('currentTag')}
    />
  ));

storiesOf('App Components/Article/Podcast', module)
  .addDecorator(withKnobs)
  .addDecorator(articleDecorator)
  .add('Default', () => (
    <Article
      {...commonProps}
      reactionsIcon={text('reactionsIcon', ICONS.REACTIONS_ICON)}
      commentsIcon={text('commentsIcon', ICONS.COMMENTS_ICON)}
      videoIcon={text('videoIcon', ICONS.VIDEO_ICON)}
      isBookmarked={boolean('isBookmarked', false)}
      article={object('article', podcastArticle)}
      currentTag={text('currentTag')}
    />
  ))
  .add('Podcast Episode', () => (
    <Article
      {...commonProps}
      reactionsIcon={text('reactionsIcon', ICONS.REACTIONS_ICON)}
      commentsIcon={text('commentsIcon', ICONS.COMMENTS_ICON)}
      videoIcon={text('videoIcon', ICONS.VIDEO_ICON)}
      isBookmarked={boolean('isBookmarked', false)}
      article={object('article', podcastEpisodeArticle)}
      currentTag={text('currentTag')}
    />
  ));

storiesOf('App Components/Article/User', module)
  .addDecorator(withKnobs)
  .addDecorator(articleDecorator)
  .add('Default', () => (
    <Article
      {...commonProps}
      reactionsIcon={text('reactionsIcon', ICONS.REACTIONS_ICON)}
      commentsIcon={text('commentsIcon', ICONS.COMMENTS_ICON)}
      videoIcon={text('videoIcon', ICONS.VIDEO_ICON)}
      article={object('article', userArticle)}
    />
  ));
