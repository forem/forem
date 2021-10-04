/*
  global selectNavigation
*/
import { h, Component } from 'preact';
import PropTypes from 'prop-types';
import { i18next } from '@utilities/locale';

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
            {i18next.t('listings.all')}
          </option>

          {categories.map((category) => {
            return (
              // eslint-disable-next-line react/jsx-key
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
