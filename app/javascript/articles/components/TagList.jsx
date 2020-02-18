import { h } from 'preact';
import { tagPropTypes } from '../../src/components/common-prop-types';

export const TagList = ({ tags = [] }) => (
  <div className="tags">
    {tags.map(tag => (
      <a href={`/t/${tag}`}>
        <span className="tag">{`#${tag}`}</span>
      </a>
    ))}
  </div>
);

TagList.propTypes = {
  tags: tagPropTypes.isRequired,
};

TagList.displayName = 'TagList';
