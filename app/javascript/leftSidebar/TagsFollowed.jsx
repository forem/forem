import { h, Fragment } from 'preact';
import ahoy from 'ahoy.js';
import PropTypes from 'prop-types';

export const TagsFollowed = ({ tags = [] }) => {
  const trackSidebarTagClick = (event) => {
    // Temporary Ahoy Stats for usage reports
    ahoy.track('Tag sidebar click', { option: event.target.href });
  };

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
            onClick={trackSidebarTagClick}
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
