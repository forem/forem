import { h, Fragment } from 'preact';
import PropTypes from 'prop-types';

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
TagsFollowed.propTypes = PropTypes.arrayOf(
  PropTypes.shape({
    id: PropTypes.number.isRequired,
    name: PropTypes.string.isRequired,
    hotness_score: PropTypes.number.isRequired,
    points: PropTypes.number.isRequired,
    bg_color_hex: PropTypes.string.isRequired,
    text_color_hex: PropTypes.string.isRequired,
  }),
);
