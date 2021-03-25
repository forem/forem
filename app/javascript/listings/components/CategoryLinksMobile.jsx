/*
  global selectNavigation
*/
import { h, Component } from 'preact';
import PropTypes from 'prop-types';

export class CategoryLinksMobile extends Component {
  componentDidMount() {
    selectNavigation('mobile_nav_listings');
  }

  render() {
    const { categories, selectedCategory } = this.props;

    return (
      <div className="block m:hidden">
        <select
          id="mobile_nav_listings"
          class="crayons-select"
          aria-label="Listings"
        >
          <option value="/listings" selected={selectedCategory === ''}>
            All listings
          </option>

          {categories.map((category) => {
            return (
              <option
                value={`/listings/${category.slug}`}
                selected={category.slug === selectedCategory}
              >
                {category.name}
              </option>
            );
          })}
        </select>
      </div>
    );
  }
}

CategoryLinksMobile.propTypes = {
  categories: PropTypes.arrayOf(
    PropTypes.shape({
      slug: PropTypes.string.isRequired,
      name: PropTypes.string.isRequired,
    }),
  ).isRequired,
  selectedCategory: PropTypes.string.isRequired,
};
