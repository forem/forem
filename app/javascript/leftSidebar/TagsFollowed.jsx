import { h } from 'preact';
import PropTypes from 'prop-types';
import { tagPropTypes } from '../src/components/common-prop-types';

export const TagsFollowed = ({ tags = [] }) => {
  // TODO: Once we're using Preact X >, we can replace the containing <div /> with a Fragment, <></>
  return (
    <div id="followed-tags-wrapper">
      {tags.map(tag => (
        <div
          key={tag.id}
          className="sidebar-nav-element"
          id={`sidebar-element-${tag.name}`}
        >
          <a
            className="sidebar-nav-link sidebar-nav-link-tag"
            href={`/t/${tag.name}`}
          >
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
