import PropTypes from 'prop-types';
import { h } from 'preact';

const Tags = ({ tagList }) => {
  const tagLinks = tagList.map((tag) => (
    <a href={`/listings?t=${tag}`} data-no-instant>
      #{tag}{' '}
    </a>
  ));

  return <span className="dashboard-listing-tags">{tagLinks}</span>;
};

Tags.propTypes = {
  tagList: PropTypes.arrayOf(PropTypes.string).isRequired,
};

export default Tags;
