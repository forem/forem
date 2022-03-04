import { h } from 'preact';
import { articlePropTypes } from '../../common-prop-types';

export const ContentTitle = ({ article }) => (
  <h3 className="crayons-story__title">
    <a href={article.path} id={`article-link-${article.id}`}>
      {article.class_name === 'PodcastEpisode' && (
        <span className="crayons-story__flare-tag">podcast</span>
      )}
      {article.class_name === 'User' && (
        <span
          className="crayons-story__flare-tag"
          style={{ background: '#5874d9', color: 'white' }}
        >
          person
        </span>
      )}
      {/* eslint-disable-next-line react/no-danger */}
      <span dangerouslySetInnerHTML={{ __html: filterXSS(article.title) }} />
    </a>
  </h3>
);

ContentTitle.propTypes = {
  article: articlePropTypes.isRequired,
};

ContentTitle.displayName = 'ContentTitle';
