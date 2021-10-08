import { h } from 'preact';
import PropTypes from 'prop-types';

export const TagList = ({ tags = [] }) => {
  return (
    <div className="crayons-story__tags">
      {tags.map((tag) => {
        return (
          <a key={`tag-${tag}`} className="crayons-tag" href={`/t/${tag}`}>
            {tag}
          </a>
        );
      })}
    </div>
  );
};

TagList.propTypes = {
  tags: PropTypes.arrayOf(PropTypes.string).isRequired,
};

TagList.displayName = 'TagList';
