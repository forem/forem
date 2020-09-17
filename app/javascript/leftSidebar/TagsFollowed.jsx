import { h } from 'preact';
import PropTypes from 'prop-types';
import { tagPropTypes } from '../common-prop-types';

export const TagsFollowed = ({ tags = [] }) => {
  // TODO: Once we're using Preact X >, we can replace the containing <div /> with a Fragment, <Fragment></Fragment>
  return (
    <div id="followed-tags-wrapper" data-testid="followed-tags">
      {tags.map((tag) => (
        <div
          key={tag.id}
          className="sidebar-nav-element"
          id={`sidebar-element-${tag.name}`}
        >
          <a
            title={`${tag.name} tag`}
            className="crayons-link crayons-link--block spec__tag-link"
            href={`/t/${tag.name}`}
          >
            {`#${tag.name}`}
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
