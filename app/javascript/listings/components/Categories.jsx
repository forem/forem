import PropTypes from 'prop-types';
import { h, Component } from 'preact';

class Categories extends Component {
  options = () => {
    const { categoriesForSelect, category } = this.props;
    return categoriesForSelect.map(([text, value]) => {
      // array example: ["Education/Courses (1 Credit)", "education"]
      if (category === value) {
        return (
          <option value={value} selected>
            {text}
          </option>
        );
      }
      return <option value={value}>{text}</option>;
    });
  };

  details = () => {
    const { categoriesForDetails } = this.props;
    const rules = categoriesForDetails.map((category) => {
      const paragraphText = `${category.name}: ${category.rules}`;
      return <p>{paragraphText}</p>;
    });

    return (
      <details>
        <summary>Category details/rules</summary>
        {rules}
      </details>
    );
  };

  render() {
    const { onChange } = this.props;
    return (
      <div className="field">
        <label className="listingform__label" htmlFor="category">
          Category
        </label>
        <select
          id="category"
          className="listingform__input"
          name="classified_listing[classified_listing_category_id]"
          onChange={onChange}
          onBlur={onChange}
        >
          {this.options()}
        </select>
        {this.details()}
      </div>
    );
  }
}

Categories.propTypes = {
  categoriesForSelect: PropTypes.arrayOf(PropTypes.string).isRequired,
  categoriesForDetails: PropTypes.arrayOf(
    PropTypes.shape({
      name: PropTypes.string,
      rules: PropTypes.string,
    }),
  ).isRequired,
  category: PropTypes.string.isRequired,
  onChange: PropTypes.func.isRequired,
};

export default Categories;
