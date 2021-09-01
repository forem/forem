import { h } from 'preact';
import { LoadingArticle } from '..';
import '../../../assets/stylesheets/articles.scss';

export default {
  title: 'App Components/Article Loading',
  component: LoadingArticle,
  // Using an arbitrary width here. This is roughly the size of articles in Storybook
  decorators: [(story) => <div style={{ minWidth: '509px' }}>{story()}</div>],
};

export const DefaultArticle = () => <LoadingArticle />;

DefaultArticle.story = {
  name: 'default',
};

export const FeaturedLoading = () => <LoadingArticle version="featured" />;

FeaturedLoading.story = {
  name: 'featured',
};
