import { h } from 'preact';
import { withKnobs, object, text, boolean } from '@storybook/addon-knobs/react';
import { action } from '@storybook/addon-actions';
import { Article } from '..';
import {
  article,
  articleWithOrganization,
  articleWithSnippetResult,
  articleWithReadingTimeGreaterThan1,
  articleWithReactions,
  articleWithComments,
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

export default {
  title: 'App Components/Article/Standard',
  component: Article,
  decorators: [withKnobs, articleDecorator],
};

export const DefaultArticle = () => (
  <Article
    {...commonProps}
    reactionsIcon={text('reactionsIcon', ICONS.REACTIONS_ICON)}
    commentsIcon={text('commentsIcon', ICONS.COMMENTS_ICON)}
    videoIcon={text('videoIcon', ICONS.VIDEO_ICON)}
    isBookmarked={boolean('isBookmarked', false)}
    article={object('article', article)}
    currentTag={text('currentTag', 'javascript')}
  />
);

DefaultArticle.story = {
  name: 'default',
};

export const WithOrganization = () => (
  <Article
    {...commonProps}
    reactionsIcon={text('reactionsIcon', ICONS.REACTIONS_ICON)}
    commentsIcon={text('commentsIcon', ICONS.COMMENTS_ICON)}
    videoIcon={text('videoIcon', ICONS.VIDEO_ICON)}
    isBookmarked={boolean('isBookmarked', false)}
    article={object('article', articleWithOrganization)}
    currentTag={text('currentTag', 'javascript')}
  />
);

WithOrganization.story = {
  name: 'with organization',
};

export const WithFlareTag = () => (
  <Article
    {...commonProps}
    reactionsIcon={text('reactionsIcon', ICONS.REACTIONS_ICON)}
    commentsIcon={text('commentsIcon', ICONS.COMMENTS_ICON)}
    videoIcon={text('videoIcon', ICONS.VIDEO_ICON)}
    isBookmarked={boolean('isBookmarked', false)}
    article={object('article', article)}
    currentTag={text('currentTag')}
  />
);

WithFlareTag.story = {
  name: 'with flare tag',
};

export const WithSnippetResult = () => (
  <Article
    {...commonProps}
    reactionsIcon={text('reactionsIcon', ICONS.REACTIONS_ICON)}
    commentsIcon={text('commentsIcon', ICONS.COMMENTS_ICON)}
    videoIcon={text('videoIcon', ICONS.VIDEO_ICON)}
    isBookmarked={boolean('isBookmarked', false)}
    article={object('article', articleWithSnippetResult)}
    currentTag={text('currentTag')}
  />
);

WithSnippetResult.story = {
  name: 'with snippet result',
};

export const WithReadingTime = () => (
  <Article
    {...commonProps}
    reactionsIcon={text('reactionsIcon', ICONS.REACTIONS_ICON)}
    commentsIcon={text('commentsIcon', ICONS.COMMENTS_ICON)}
    videoIcon={text('videoIcon', ICONS.VIDEO_ICON)}
    isBookmarked={boolean('isBookmarked', false)}
    article={object('article', articleWithReadingTimeGreaterThan1)}
    currentTag={text('currentTag')}
  />
);

WithReadingTime.story = {
  name: 'with reading time',
};

export const WithReactions = () => (
  <Article
    {...commonProps}
    reactionsIcon={text('reactionsIcon', ICONS.REACTIONS_ICON)}
    commentsIcon={text('commentsIcon', ICONS.COMMENTS_ICON)}
    videoIcon={text('videoIcon', ICONS.VIDEO_ICON)}
    isBookmarked={boolean('isBookmarked', false)}
    article={object('article', articleWithReactions)}
    currentTag={text('currentTag')}
  />
);

WithReactions.story = {
  name: 'with reactions',
};

export const WithComments = () => (
  <Article
    {...commonProps}
    reactionsIcon={text('reactionsIcon', ICONS.REACTIONS_ICON)}
    commentsIcon={text('commentsIcon', ICONS.COMMENTS_ICON)}
    videoIcon={text('videoIcon', ICONS.VIDEO_ICON)}
    isBookmarked={boolean('isBookmarked', false)}
    article={object('article', articleWithComments)}
    currentTag={text('currentTag')}
  />
);

WithComments.story = {
  name: 'with comments',
};

export const OnReadingList = () => (
  <Article
    {...commonProps}
    reactionsIcon={text('reactionsIcon', ICONS.REACTIONS_ICON)}
    commentsIcon={text('commentsIcon', ICONS.COMMENTS_ICON)}
    videoIcon={text('videoIcon', ICONS.VIDEO_ICON)}
    isBookmarked={boolean('isBookmarked', true)}
    article={object('article', articleWithComments)}
    currentTag={text('currentTag')}
  />
);

OnReadingList.story = {
  name: 'on reading list',
};
