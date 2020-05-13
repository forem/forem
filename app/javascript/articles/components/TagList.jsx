import { h } from 'preact';
import { tagPropTypes } from '../../src/components/common-prop-types';

export const TagList = ({ tags = [] }) => (
  <div className="crayons-story__tags">
    {tags.map(tag => (
      <a className="crayons-tag" href={`/t/${tag}`}>
        <span className="crayons-tag__prefix">#</span>
        {tag}
      </a>
    ))}
  </div>
);

TagList.propTypes = {
  tags: tagPropTypes.isRequired,
};

TagList.displayName = 'TagList';
