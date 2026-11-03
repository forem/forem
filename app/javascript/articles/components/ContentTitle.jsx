import { h } from 'preact';
import { articlePropTypes } from '../../common-prop-types';

export const ContentTitle = ({ article }) => {
  if (article.title === '[Boost]' && article.user) {
    return (
      <h3 className={`crayons-story__title crayons-story__title-${article.type_of}`}>
        <span
          id={`article-link-${article.id}`}
          className="crayons-story__innertitle-boost"
        >
          <svg
            width="14"
            height="14"
            viewBox="0 0 24 24"
            aria-hidden="true"
            className="crayons-icon mr-1 align-text-bottom"
          >
            <path d="M13 10h7l-9 13v-9H4l9-13z" />
          </svg>
          Boosted by{' '}
          <a href={`/${article.user.username}`}>{article.user.name}</a>
        </span>
      </h3>
    );
  }

  return (
    <h3 className={`crayons-story__title crayons-story__title-${article.type_of}`}>
      <a href={article.url} id={`article-link-${article.id}`}>
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
        <span
          dangerouslySetInnerHTML={{
            __html:
              article.type_of === 'status' && article.title_finalized_for_feed
                ? article.title_finalized_for_feed
                : filterXSS(article.title),
          }}
        />
      </a>
    </h3>
  );
};

ContentTitle.propTypes = {
  article: articlePropTypes.isRequired,
};

ContentTitle.displayName = 'ContentTitle';
