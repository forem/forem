import { h } from 'preact';
import PropTypes from 'prop-types';

const CategoryLinks = ({ categories, onClick, selectedCategory }) => {
  return (
    <section>
      {categories.map((category) => (
        <a
          href={`/listings/${category.slug}`}
          id={`category-link-${category.id}`}
          className={category.slug === selectedCategory ? 'selected' : ''}
          onClick={(e) => {
            onClick(e, category.slug);
          }}
          data-no-instant
          Key={category.id}
        >
          {category.name}
        </a>
      ))}
    </section>
  );
};

CategoryLinks.propTypes = {
  categories: PropTypes.isRequired,
  onClick: PropTypes.func.isRequired,
  selectedCategory: PropTypes.string.isRequired,
};

export default CategoryLinks;
