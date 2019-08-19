import PropTypes from 'prop-types';
import { h } from 'preact';

const ExpireDate = ({ onChange, defaultValue }) => {
  let tomorrow = new Date();
  let monthFromToday = new Date();
  tomorrow.setDate(new Date().getDate() + 1);
  tomorrow = tomorrow.toISOString().split('T')[0];
  monthFromToday.setDate(new Date().getDate() + 30);
  monthFromToday = monthFromToday.toISOString().split('T')[0];
  
  return (
    <div className="field">
      <label className="listingform__label" htmlFor="expire_on">Custom Expire Date (if applicable for time sensitive events, deadlines, etc.)</label>
      <input
        type="date"
        className="listingform__input"
        id="expire_on"
        name="classified_listing[expire_on]"
        value={defaultValue}
        onInput={onChange}
        min={tomorrow}
        max={monthFromToday}
      />
    </div>
  );
}

ExpireDate.propTypes = {
  onChange: PropTypes.func.isRequired,
  defaultValue: PropTypes.string.isRequired,
}
  
export default ExpireDate;
