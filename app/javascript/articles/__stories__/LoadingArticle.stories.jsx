import { h } from 'preact';
import { LoadingArticle } from '..';
import '../../../assets/stylesheets/articles.scss';
import { articleDecorator } from './articleDecorator';

export default {
  title: 'App Components/Article',
  decorators: [articleDecorator],
};

export const ArticleLoading = () => <LoadingArticle />;

ArticleLoading.story = {
  name: 'article loading',
};

export const FeaturedArticleLoading = () => (
  <LoadingArticle version="featured" />
);

FeaturedArticleLoading.story = {
  name: 'featured article loading',
};
