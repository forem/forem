import { h } from 'preact';
import { articlePropTypes } from '../../common-prop-types';

export const ContentTitle = ({ article }) => (
  <h2 className="crayons-story__title">
    <a href={article.path} id={`article-link-${article.id}`}>
      {article.flare_tag && (
        <span
          className="crayons-story__flare-tag"
          style={{
            background: article.flare_tag.bg_color_hex,
            color: article.flare_tag.text_color_hex,
          }}
        >
          {`#${article.flare_tag.name}`}
        </span>
      )}
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
      <span dangerouslySetInnerHTML={{ __html: filterXSS(article.title) }} />
    </a>
  </h2>
);

ContentTitle.propTypes = {
  article: articlePropTypes.isRequired,
};

ContentTitle.displayName = 'ContentTitle';
