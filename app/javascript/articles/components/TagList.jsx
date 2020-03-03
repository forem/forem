import { h } from 'preact';
import PropTypes from 'prop-types';
import { tagPropTypes } from '../../src/components/common-prop-types';

export const TagList = ({ tags = [], className }) => (
  <div className={`tags${className ? ` ${className}` : ''}`}>
    {tags.map(tag => (
      <a href={`/t/${tag}`}>
        <span className="tag">{`#${tag}`}</span>
      </a>
    ))}
  </div>
);

TagList.defaultProps = {
  className: null,
};

TagList.propTypes = {
  tags: tagPropTypes.isRequired,
  className: PropTypes.string,
};

TagList.displayName = 'TagList';
