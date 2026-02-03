import { h } from 'preact';
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
  argTypes: {
    isBookmarked: {
      control: { type: 'boolean' },
    },
    isFeatured: {
      control: { type: 'boolean' },
    },
    currentTag: {
      control: { type: 'text' },
    },
    article: {
      control: { type: 'object' },
    },
  },
  args: {
    isBookmarked: false,
    isFeatured: false,
    currentTag: 'javascript',
    article: article,
  },
};

export const DefaultArticle = (args) => (
  <Article
    {...commonProps}
    isBookmarked={args.isBookmarked}
    article={args.article}
    currentTag={args.currentTag}
  />
);

DefaultArticle.storyName = 'default';

export const IsFeatured = (args) => (
  <Article
    {...commonProps}
    isBookmarked={args.isBookmarked}
    isFeatured={true}
    article={featuredArticle}
    currentTag={args.currentTag}
  />
);

IsFeatured.storyName = 'is featured';

export const WithOrganization = (args) => (
  <Article
    {...commonProps}
    isBookmarked={args.isBookmarked}
    article={articleWithOrganization}
    currentTag={args.currentTag}
  />
);

WithOrganization.storyName = 'with organization';

export const WithFlareTag = (args) => (
  <Article
    {...commonProps}
    isBookmarked={args.isBookmarked}
    article={args.article}
    currentTag={args.currentTag}
  />
);

WithFlareTag.storyName = 'with flare tag';

export const WithSnippetResult = (args) => (
  <Article
    {...commonProps}
    isBookmarked={args.isBookmarked}
    article={articleWithSnippetResult}
    currentTag={args.currentTag}
  />
);

WithSnippetResult.storyName = 'with snippet result';

export const WithReactions = (args) => (
  <Article
    {...commonProps}
    isBookmarked={args.isBookmarked}
    article={articleWithReactions}
    currentTag={args.currentTag}
  />
);

WithReactions.storyName = 'with reactions';

export const WithComments = (args) => (
  <Article
    {...commonProps}
    isBookmarked={args.isBookmarked}
    article={articleWithComments}
    currentTag={args.currentTag}
  />
);

WithComments.storyName = 'with comments';

export const OnReadingList = (args) => (
  <Article
    {...commonProps}
    isBookmarked={true}
    article={args.article}
    currentTag={args.currentTag}
  />
);

OnReadingList.storyName = 'on reading list';
