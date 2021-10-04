import PropTypes from 'prop-types';
import { h, Component } from 'preact';
import { i18next } from '@utilities/locale';

export class Categories extends Component {
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
      // eslint-disable-next-line react/jsx-key
      return <option value={value}>{text}</option>;
    });
  };

  details = () => {
    const { categoriesForDetails } = this.props;
    const rules = categoriesForDetails.map((category) => {
      const paragraphText = (
        <li>
          <strong>{category.name}:</strong> {category.rules}
        </li>
      );
      // eslint-disable-next-line react/jsx-key
      return <ul>{paragraphText}</ul>;
    });

    return (
      <details>
        <summary>{i18next.t('listings.form.category.summary')}</summary>
        {rules}
      </details>
    );
  };

  render() {
    const { onChange } = this.props;
    return (
      <div>
        <div className="crayons-field mb-4">
          <label className="crayons-field__label" htmlFor="category">
            {i18next.t('listings.form.category.label')}
          </label>
          <select
            id="category"
            className="crayons-select"
            name="listing[listing_category_id]"
            onChange={onChange}
            onBlur={onChange}
          >
            {this.options()}
          </select>
        </div>
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
