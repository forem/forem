import PropTypes from 'prop-types';
import { h } from 'preact';

const TagLinks = ({ tags, onClick }) => (
  <div className="single-classified-listing-tags">
    {tags.length
      ? tags.map(tag => {
          return (
            <a
              href={`/listings?t=${tag}`}
              onClick={e => onClick(e, tag)}
              data-no-instant
            >
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

export default TagLinks;
