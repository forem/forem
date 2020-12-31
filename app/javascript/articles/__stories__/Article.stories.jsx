import { h } from 'preact';
import { withKnobs, object, text, boolean } from '@storybook/addon-knobs';
import { action } from '@storybook/addon-actions';
import { Article } from '..';
import {
  article,
  articleWithOrganization,
  articleWithSnippetResult,
  articleWithReactions,
  articleWithComments,
  featuredArticle,
} from '../__tests__/utilities/articleUtilities';

import '../../../assets/stylesheets/articles.scss';

const commonProps = {
  bookmarkClick: action('Saved/unsaved article'),
};

export default {
  title: 'App Components/Article/Standard',
  component: Article,
  decorators: [withKnobs],
};

export const DefaultArticle = () => (
  <Article
    {...commonProps}
    isBookmarked={boolean('isBookmarked', false)}
    article={object('article', article)}
    currentTag={text('currentTag', 'javascript')}
  />
);

DefaultArticle.story = {
  name: 'default',
};

export const IsFeatured = () => (
  <Article
    {...commonProps}
    isBookmarked={boolean('isBookmarked', false)}
    isFeatured={boolean('isFeatured', true)}
    article={object('article', featuredArticle)}
    currentTag={text('currentTag', 'javascript')}
  />
);

IsFeatured.story = {
  name: 'is featured',
};

export const WithOrganization = () => (
  <Article
    {...commonProps}
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
    isBookmarked={boolean('isBookmarked', false)}
    article={object('article', articleWithSnippetResult)}
    currentTag={text('currentTag')}
  />
);

WithSnippetResult.story = {
  name: 'with snippet result',
};

export const WithReactions = () => (
  <Article
    {...commonProps}
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
    isBookmarked={boolean('isBookmarked', true)}
    article={object('article', article)}
    currentTag={text('currentTag')}
  />
);

OnReadingList.story = {
  name: 'on reading list',
};
