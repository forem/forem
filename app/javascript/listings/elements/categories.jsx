import PropTypes from 'prop-types';
import { h, Component } from 'preact';

class Categories extends Component {
  options = () => {
    const { categoriesForSelect, category } = this.props
    return categoriesForSelect.map(array => {
      // array example: ["Education/Courses (1 Credit)", "education"]
      if(category === array[1]) {
        return(
          <option value={array[1]} selected>{array[0]}</option>
        )
      }
      return(
        <option value={array[1]}>{array[0]}</option>
      )
    })
  }

  details = () => {
    const { categoriesForDetails } = this.props
    const rules = categoriesForDetails.map(category => {
      const paragraphText = `${category.name}: ${category.rules}`
      return(
        <p>
          {paragraphText}
        </p>
      )
    })

    return(
      <details>
        <summary>
          Category details/rules
        </summary>
        {rules}
      </details>
    )
  }

  render() {
    const { onChange } = this.props
    return(
      <div className="field">
        <label className="listingform__label" htmlFor="category">
          Category
        </label>
        <select className="listingform__input" name="classified_listing[category]" onChange={onChange} >
          {this.options()}
        </select>
        {this.details()}
      </div>
    )
  }
}

Categories.propTypes = {
  categoriesForSelect: PropTypes.array.isRequired,
  categoriesForDetails: PropTypes.array.isRequired,
  category: PropTypes.string.isRequired,
  onChange: PropTypes.func.isRequired,
}

export default Categories;
