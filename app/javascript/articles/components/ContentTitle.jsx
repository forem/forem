import { h } from 'preact';
import PropTypes from 'prop-types';

import { articlePropTypes } from '../../src/components/common-prop-types';

export const ContentTitle = ({ article, currentTag }) => (
  <h3>
    {article.flare_tag && currentTag !== article.flare_tag.name && (
      <span
        className="tag-identifier"
        style={{
          background: article.flare_tag.bg_color_hex,
          color: article.flare_tag.text_color_hex,
        }}
      >
        {`#${article.flare_tag.name}`}
      </span>
    )}
    {article.class_name === 'PodcastEpisode' && (
      <span className="tag-identifier">podcast</span>
    )}
    {article.class_name === 'User' && (
      <span
        className="tag-identifier"
        style={{ background: '#5874d9', color: 'white' }}
      >
        person
      </span>
    )}
    {filterXSS(article.title)}
  </h3>
);

ContentTitle.defaultProps = {
  currentTag: null,
};

ContentTitle.propTypes = {
  article: articlePropTypes.isRequired,
  currentTag: PropTypes.string,
};

ContentTitle.displayName = 'ContentTitle';
