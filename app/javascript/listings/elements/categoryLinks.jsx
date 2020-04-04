import { h } from 'preact';
import PropTypes from 'prop-types';

const CategoryLinks = ({ categories, onClick }) =>
  categories.map((category) => (
    <a
      href={`/listings/${category.slug}`}
      className={category.slug === category ? 'selected' : ''}
      onClick={onClick}
      data-no-instant
      Key={category.id}
    >
      {category.name}
    </a>
  ));

CategoryLinks.propTypes = {
  categories: PropTypes.isRequired,
  onClick: PropTypes.func.isRequired,
};

export default CategoryLinks;
