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
      {tags.map(({ name, id, points }) =>
        points >= 1 ? (
          <div
            key={id}
            className="sidebar-nav-element"
            id={`sidebar-element-${name}`}
          >
            <a
              title={`${name} tag`}
              onClick={trackSidebarTagClick}
              className="crayons-link crayons-link--block"
              href={`/t/${name}`}
            >
              {`#${name}`}
            </a>
          </div>
        ) : null,
      )}
    </Fragment>
  );
};

TagsFollowed.displayName = 'TagsFollowed';
TagsFollowed.propTypes = {
  tags: PropTypes.arrayOf(
    PropTypes.shape({
      id: PropTypes.number.isRequired,
      name: PropTypes.string.isRequired,
      points: PropTypes.number.isRequired,
    }),
  ),
};
