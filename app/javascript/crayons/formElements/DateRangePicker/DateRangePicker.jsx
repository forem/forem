import { h } from 'preact';
import PropTypes from 'prop-types';
import { useState } from 'preact/hooks';
import 'react-dates/initialize';
import 'react-dates/lib/css/_datepicker.css';
import moment from 'moment';
import { DateRangePicker as ReactDateRangePicker } from 'react-dates';
import { START_DATE } from 'react-dates/constants';
import { ButtonNew as Button } from '@crayons';

const MONTH_NAMES = [...Array(12).keys()].map((key) =>
  new Date(0, key).toLocaleString('en', { month: 'long' }),
);

// TODO: Some weirdness with validation? Not all months valid for all years :-/
const MonthYearPicker = ({
  earliestDate,
  latestDate,
  onMonthSelect,
  onYearSelect,
  month,
}) => {
  const yearsDiff = latestDate.diff(earliestDate, 'years');

  const years = [...Array(yearsDiff).keys()].map(
    (key) => latestDate.year() - key,
  );
  years.push(earliestDate.year());

  return (
    <div>
      <select
        className="crayons-select w-auto"
        onChange={(e) => onMonthSelect(month, e.target.value)}
        value={month.month()}
      >
        {MONTH_NAMES.map((month, index) => (
          <option value={index + 1} key={month}>
            {month}
          </option>
        ))}
      </select>
      <select
        className="crayons-select w-auto"
        onChange={(e) => onYearSelect(month, e.target.value)}
        value={month.year()}
      >
        {years.map((year) => (
          <option key={year} value={year}>
            {year}
          </option>
        ))}
      </select>
    </div>
  );
};

/**
 * Used to facilitate picking a date range. This component is a wrapper around the one provided from react-dates.
 *
 * @param {Object} props
 * @param {string} startDateId A unique ID for the start date input
 * @param {string} endDateId A unique ID for the end date input
 * @param {Date} defaultStartDate The optional initial value for the start date
 * @param {Date} defaultEndDate The optional initial value for the end date
 * @param {Function} onDatesChanged Callback function for when dates are selected. Receives an object with startDate and endDate values.
 */
export const DateRangePicker = ({
  startDateId,
  endDateId,
  defaultStartDate,
  defaultEndDate,
  maxEndDate = new Date(),
  minStartDate = new Date(),
  onDatesChanged,
}) => {
  const [focusedInput, setFocusedInput] = useState(START_DATE);
  const [startDate, setStartDate] = useState(
    defaultStartDate ? moment(defaultStartDate) : null,
  );
  const [endDate, setEndDate] = useState(
    defaultEndDate ? moment(defaultEndDate) : null,
  );

  const earliestDate = moment(minStartDate);
  const latestDate = moment(maxEndDate);

  return (
    // We wrap in a span to assist with scoping CSS selectors & overriding styles from react-dates
    <span className="c-date-picker">
      <ReactDateRangePicker
        startDateId={startDateId}
        startDate={startDate}
        endDate={endDate}
        endDateId={endDateId}
        focusedInput={focusedInput}
        onFocusChange={(focusedInput) => setFocusedInput(focusedInput)}
        onDatesChange={({ startDate, endDate }) => {
          setStartDate(startDate);
          setEndDate(endDate);
          onDatesChanged?.({
            startDate: startDate.toDate(),
            endDate: endDate.toDate(),
          });
        }}
        showClearDates
        renderMonthElement={(props) => (
          <MonthYearPicker
            earliestDate={earliestDate}
            latestDate={latestDate}
            {...props}
          />
        )}
        renderCalendarInfo={() => (
          <div className="p-4 ">
            TODO
            <Button>Last week</Button>
            <Button>Last month</Button>
          </div>
        )}
      />
    </span>
  );
};

DateRangePicker.propTypes = {
  startDateId: PropTypes.string.isRequired,
  endDateId: PropTypes.string.isRequired,
  defaultStartDate: PropTypes.instanceOf(Date),
  defaultEndDate: PropTypes.instanceOf(Date),
  onDatesChanged: PropTypes.func,
};
