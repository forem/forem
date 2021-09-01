import PropTypes from 'prop-types';
import { h } from 'preact';

export const ExpireDate = ({ onChange, defaultValue }) => {
  let tomorrow = new Date();
  let monthFromToday = new Date();
  tomorrow.setDate(new Date().getDate() + 1);
  [tomorrow] = tomorrow.toISOString().split('T');
  monthFromToday.setDate(new Date().getDate() + 30);
  [monthFromToday] = monthFromToday.toISOString().split('T');

  return (
    <div className="crayons-field">
      <label className="crayons-field__label" htmlFor="expires_at">
        Custom Expire Date
        <p class="crayons-field__description">
          If applicable for time sensitive events, deadlines, etc.
        </p>
      </label>
      <input
        type="date"
        className="crayons-textfield m:max-w-50"
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
