import { h } from 'preact';
import PropTypes from 'prop-types';
import { articlePropTypes } from '../../src/components/common-prop-types';

export const ReactionsCount = ({ article, icon }) => {
  const totalReactions = article.positive_reactions_count || 0;

  return (
    <div className="article-engagement-count reactions-count">
      <a href={article.path}>
        <img src={icon} alt="heart" loading="lazy" />
        <span
          id={`engagement-count-number-${article.id}`}
          className="engagement-count-number"
        >
          {totalReactions}
        </span>
      </a>
    </div>
  );
};

ReactionsCount.propTypes = {
  article: articlePropTypes.isRequired,
  icon: PropTypes.string.isRequired,
};

ReactionsCount.displayName = 'ReactionsCount';
