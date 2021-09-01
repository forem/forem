import PropTypes from 'prop-types';
import { h } from 'preact';

export const TagLinks = ({ tags, onClick }) => (
  <div className="-ml-1 single-listing__tags">
    {tags.length
      ? tags.map((tag) => {
          return (
            <a
              href={`/listings?t=${tag}`}
              onClick={(e) => onClick(e, tag)}
              className="crayons-tag"
              data-no-instant
            >
              <span className="crayons-tag__prefix">#</span>
              {tag}
            </a>
          );
        })
      : null}
  </div>
);

TagLinks.propTypes = {
  tags: PropTypes.arrayOf(PropTypes.string),
  onClick: PropTypes.func.isRequired,
};

TagLinks.defaultProps = {
  tags: [],
};
