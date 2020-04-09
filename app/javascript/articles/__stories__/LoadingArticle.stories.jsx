import { h } from 'preact';
import { LoadingArticle } from '..';
import '../../../assets/stylesheets/articles.scss';
import { articleDecorator } from './articleDecorator';

export default {
  title: 'App Components/Article Loading',
  component: LoadingArticle,
  decorators: [articleDecorator],
};

export const DefaultArticle = () => <LoadingArticle />;

DefaultArticle.story = {
  name: 'default',
};

export const FeaturedLoading = () => (
  <LoadingArticle version="featured" />
);

FeaturedLoading.story = {
  name: 'featured',
};
