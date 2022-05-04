import { h } from 'preact';
import PropTypes from 'prop-types';
import { useState } from 'preact/hooks';
import 'react-dates/initialize';
import 'react-dates/lib/css/_datepicker.css';
import moment from 'moment';
import { DateRangePicker as ReactDateRangePicker } from 'react-dates';
import { START_DATE } from 'react-dates/constants';
import { ButtonNew as Button } from '@crayons';

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
  onDatesChanged,
}) => {
  const [focusedInput, setFocusedInput] = useState(START_DATE);
  const [startDate, setStartDate] = useState(
    defaultStartDate ? moment(defaultStartDate) : null,
  );
  const [endDate, setEndDate] = useState(
    defaultEndDate ? moment(defaultEndDate) : null,
  );

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
        renderMonthElement={() => (
          <div>
            <select className="crayons-select w-auto">
              <option value="1">January</option>
            </select>
            <select className="crayons-select w-auto">
              <option value="1">2022</option>
            </select>
          </div>
        )}
        renderCalendarInfo={() => (
          <div className="p-4 ">
            <Button variant="secondary mr-2">Last week</Button>
            <Button variant="secondary">Last month</Button>
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
