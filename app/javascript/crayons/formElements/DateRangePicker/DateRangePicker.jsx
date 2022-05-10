import { h } from 'preact';
import PropTypes from 'prop-types';
import { useState } from 'preact/hooks';
import 'react-dates/initialize';
import 'react-dates/lib/css/_datepicker.css';
import moment from 'moment';
import { DateRangePicker as ReactDateRangePicker } from 'react-dates';
import {
  START_DATE,
  ICON_AFTER_POSITION,
  ICON_BEFORE_POSITION,
} from 'react-dates/constants';
import { ButtonNew as Button, Icon } from '@crayons';
import ChevronLeft from '@images/chevron-left.svg';
import ChevronRight from '@images/chevron-right.svg';
import Calendar from '@images/calendar.svg';

const MONTH_NAMES = [...Array(12).keys()].map((key) =>
  new Date(0, key).toLocaleString('en', { month: 'long' }),
);

const isDateOutsideOfRange = ({ date, minDate, maxDate }) =>
  !date.isBetween(minDate, maxDate);

// TODO:
// - Consolidate styling
// - Clarify if we can show calendar button and clear button
// - Test in other browsers
// - Test app start up OK
// - Update story props and add documentation
// - Snapshot tests
// - Component tests

const MonthYearPicker = ({
  earliestMoment,
  latestMoment,
  onMonthSelect,
  onYearSelect,
  month,
}) => {
  const yearsDiff = latestMoment.diff(earliestMoment, 'years');

  const years = [...Array(yearsDiff).keys()].map(
    (key) => latestMoment.year() - key,
  );
  years.push(earliestMoment.year());

  return (
    <div>
      <select
        className="crayons-select w-auto mr-2 fs-s"
        onChange={(e) => onMonthSelect(month, e.target.value)}
        value={month.month()}
      >
        {MONTH_NAMES.map((month, index) => (
          <option value={index} key={month}>
            {month}
          </option>
        ))}
      </select>
      <select
        className="crayons-select w-auto fs-s"
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
 * @param {string} props.startDateId A unique ID for the start date input
 * @param {string} props.endDateId A unique ID for the end date input
 * @param {Date} props.defaultStartDate The optional initial value for the start date
 * @param {Date} props.defaultEndDate The optional initial value for the end date
 * @param {Date} props.maxEndDate The latest date that may be selected
 * @param {Date} props.minStartDate The oldest date that may be selected
 * @param {Function} props.onDatesChanged Callback function for when dates are selected. Receives an object with startDate and endDate values.
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
  const [startMoment, setStartMoment] = useState(
    defaultStartDate ? moment(defaultStartDate) : null,
  );
  const [endMoment, setEndMoment] = useState(
    defaultEndDate ? moment(defaultEndDate) : null,
  );

  const earliestMoment = moment(minStartDate);
  const latestMoment = moment(maxEndDate);

  return (
    // We wrap in a span to assist with scoping CSS selectors & overriding styles from react-dates
    <span className="c-date-picker">
      <ReactDateRangePicker
        startDateId={startDateId}
        startDate={startMoment}
        endDate={endMoment}
        endDateId={endDateId}
        focusedInput={focusedInput}
        navPrev={<Icon src={ChevronLeft} />}
        navNext={<Icon src={ChevronRight} />}
        customInputIcon={<Icon src={Calendar} />}
        showDefaultInputIcon={!(startMoment || endMoment)}
        inputIconPosition={ICON_BEFORE_POSITION}
        showClearDates={startMoment || endMoment}
        customArrowIcon="-"
        onFocusChange={(focusedInput) => setFocusedInput(focusedInput)}
        isOutsideRange={(date) =>
          isDateOutsideOfRange({
            date,
            minDate: earliestMoment,
            maxDate: latestMoment,
          })
        }
        onDatesChange={({ startDate, endDate }) => {
          setStartMoment(startDate);
          setEndMoment(endDate);
          onDatesChanged?.({
            startDate: startDate.toDate(),
            endDate: endDate.toDate(),
          });
        }}
        renderMonthElement={(props) => (
          <MonthYearPicker
            earliestMoment={earliestMoment}
            latestMoment={latestMoment}
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
