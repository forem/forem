import PropTypes from 'prop-types';
import { h } from 'preact';

const ExpireDate = ({ onChange, defaultValue }) => {
  let tomorrow = new Date();
  let monthFromToday = new Date();
  tomorrow.setDate(new Date().getDate() + 1);
  [tomorrow] = tomorrow.toISOString().split('T');
  monthFromToday.setDate(new Date().getDate() + 30);
  [monthFromToday] = monthFromToday.toISOString().split('T');

  return (
    <div className="field">
      <label className="listingform__label" htmlFor="expires_at">
        Custom Expire Date (if applicable for time sensitive events, deadlines,
        etc.)
      </label>
      <input
        type="date"
        className="listingform__input"
        id="expires_at"
        name="listing[expires_at]"
        value={defaultValue}
        onInput={onChange}
        min={tomorrow}
        max={monthFromToday}
      />
    </div>
  );
};

ExpireDate.propTypes = {
  onChange: PropTypes.func.isRequired,
  defaultValue: PropTypes.string.isRequired,
};

export default ExpireDate;
