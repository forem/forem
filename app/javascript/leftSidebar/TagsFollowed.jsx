import { h } from 'preact';
import PropTypes from 'prop-types';
import { tagPropTypes } from '../src/components/common-prop-types';

export const TagsFollowed = ({ tags = [] }) => {
  return (
    <div id="sidebar-nav-followed-tags" className="sidebar-nav-followed-tags">
      {tags.map(tag => (
        <div
          key={tag.id}
          className="sidebar-nav-element"
          id={`sidebar-element-${tag.name}`}
        >
          <a className="sidebar-nav-link" href={`/t/${tag.name}`}>
            <span className="sidebar-nav-tag-text">{`#${tag.name}`}</span>
          </a>
        </div>
      ))}
    </div>
  );
};

TagsFollowed.displayName = 'TagsFollowed';
TagsFollowed.propTypes = {
  tags: PropTypes.arrayOf(tagPropTypes).isRequired,
};
