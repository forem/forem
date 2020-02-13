import { h } from 'preact';
import { defaultChildrenPropTypes } from '../../src/components/common-prop-types';

const ArticleWrapper = ({ children }) => (
  <div className="articles-list">{children}</div>
);
ArticleWrapper.propTypes = {
  children: defaultChildrenPropTypes.isRequired,
};
ArticleWrapper.displayName = 'ArticleWrapper';

export const articleDecorator = getStory => (
  <ArticleWrapper>{getStory()}</ArticleWrapper>
);
