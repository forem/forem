import { h, Fragment } from 'preact';
import PropTypes from 'prop-types';
import { tagPropTypes } from '../common-prop-types';

export const TagsFollowed = ({ tags = [] }) => {
  return (
    <Fragment>
      {tags.map((tag) => (
        <div
          key={tag.id}
          className="sidebar-nav-element"
          id={`sidebar-element-${tag.name}`}
        >
          <a
            title={`${tag.name} tag`}
            className="crayons-link crayons-link--block"
            href={`/t/${tag.name}`}
          >
            {`#${tag.name}`}
          </a>
        </div>
      ))}
    </Fragment>
  );
};

TagsFollowed.displayName = 'TagsFollowed';
TagsFollowed.propTypes = {
  tags: PropTypes.arrayOf(tagPropTypes).isRequired,
};
