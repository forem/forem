import { h } from 'preact';
import { storiesOf } from '@storybook/react';
import { LoadingArticle } from '..';
import { defaultChildrenPropTypes } from '../../src/components/common-prop-types/default-children-prop-types';
import '../../../assets/stylesheets/articles.scss';

const ArticleWrapper = ({ children }) => (
  <div className="articles-list">{children}</div>
);
ArticleWrapper.propTypes = {
  children: defaultChildrenPropTypes.isRequired,
};
ArticleWrapper.displayName = 'ArticleWrapper';

storiesOf('Components/Articles/Loading Article', module).add('Default', () => (
  <ArticleWrapper>
    <LoadingArticle />
  </ArticleWrapper>
));
