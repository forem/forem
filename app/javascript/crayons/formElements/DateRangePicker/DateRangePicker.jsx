import { h } from 'preact';
import PropTypes from 'prop-types';
import { useState } from 'preact/hooks';
import 'react-dates/initialize';
import moment from 'moment';
import { DateRangePicker as ReactDateRangePicker } from 'react-dates';
import defaultPhrases from 'react-dates/lib/defaultPhrases';
import {
  START_DATE,
  ICON_BEFORE_POSITION,
  VERTICAL_ORIENTATION,
  HORIZONTAL_ORIENTATION,
} from 'react-dates/constants';
import { Icon } from '@crayons';
import ChevronLeft from '@images/chevron-left.svg';
import ChevronRight from '@images/chevron-right.svg';
import Calendar from '@images/calendar.svg';
import { getCurrentLocale } from '@utilities/runtime';
import { useMediaQuery, BREAKPOINTS } from '@components/useMediaQuery';

const PICKER_PHRASES = {
  ...defaultPhrases,
  chooseAvailableStartDate: ({ date }) => `Choose ${date} as start date`,
  chooseAvailableEndDate: ({ date }) => `Choose ${date} as end date`,
  focusStartDate: 'Interact with the calendar and add your start date',
};

const MONTH_NAMES = [...Array(12).keys()].map((key) =>
  new Date(0, key).toLocaleString('en', { month: 'long' }),
);

const isDateOutsideOfRange = ({ date, minDate, maxDate }) =>
  !date.isBetween(minDate, maxDate);

const MonthYearPicker = ({
  earliestMoment,
  latestMoment,
  onMonthSelect,
  onYearSelect,
  month,
}) => {
  const selectedMonth = month.month();
  const selectedYear = month.year();

  const latestYear = latestMoment.year();

  // Make sure we only display the available months for the currently selected year
  const latestMonthIndex =
    latestYear === selectedYear ? latestMoment.month() : 11;
  const availableMonths = MONTH_NAMES.slice(0, latestMonthIndex + 1);

  const yearsDiff = latestMoment.diff(earliestMoment, 'years');

  const years = [...Array(yearsDiff).keys()].map(
    (key) => latestMoment.year() - key,
  );
  years.push(earliestMoment.year());

  return (
    <div className="c-date-picker__month">
      <select
        aria-label="Navigate to month"
        className="crayons-select w-auto mr-2 fs-s"
        onChange={(e) => onMonthSelect(month, e.target.value)}
        value={selectedMonth}
      >
        {availableMonths.map((month, index) => (
          <option value={index} key={month}>
            {month}
          </option>
        ))}
      </select>
      <select
        aria-label="Navigate to year"
        className="crayons-select w-auto fs-s"
        onChange={(e) => onYearSelect(month, e.target.value)}
        value={selectedYear}
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

  const useCompactLayout = useMediaQuery(
    `(max-width: ${BREAKPOINTS.Medium - 1}px)`,
  );

  const earliestMoment = moment(minStartDate);
  const latestMoment = moment(maxEndDate);

  const isMonthSameAsLatestMonth = (relevantDate) =>
    relevantDate.year() === latestMoment.year() &&
    relevantDate.month() === latestMoment.month();

  const today = moment();
  const dateFormat =
    getCurrentLocale().toLowerCase() === 'en-us' ? 'MM/DD/YYYY' : 'DD/MM/YYYY';

  return (
    // We wrap in a span to assist with scoping CSS selectors & overriding styles from react-dates
    <span className="c-date-picker">
      <ReactDateRangePicker
        startDateId={startDateId}
        startDate={startMoment}
        endDate={endMoment}
        endDateId={endDateId}
        startDatePlaceholderText={dateFormat}
        endDatePlaceholderText={dateFormat}
        displayFormat={dateFormat}
        focusedInput={focusedInput}
        // It is strange to add a tabindex to an icon, but react-dates renders these inside a role="button" which does not have a tabindex
        // This is a workaround to make sure keyboard users can reach and interact with the nav buttons
        navPrev={<Icon tabindex="0" src={ChevronLeft} />}
        navNext={<Icon tabindex="0" src={ChevronRight} />}
        minDate={earliestMoment}
        maxDate={latestMoment}
        initialVisibleMonth={() => {
          let relevantDate = startMoment;

          if (!relevantDate) {
            relevantDate = latestMoment ? latestMoment : today;
          }

          return isMonthSameAsLatestMonth(relevantDate)
            ? relevantDate.clone().subtract(1, 'month')
            : relevantDate;
        }}
        customInputIcon={<Icon src={Calendar} />}
        showDefaultInputIcon={!(startMoment || endMoment)}
        inputIconPosition={ICON_BEFORE_POSITION}
        orientation={
          useCompactLayout ? VERTICAL_ORIENTATION : HORIZONTAL_ORIENTATION
        }
        showClearDates={startMoment || endMoment}
        customArrowIcon="-"
        phrases={PICKER_PHRASES}
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
        small={useCompactLayout}
        renderMonthElement={(props) => (
          <MonthYearPicker
            earliestMoment={earliestMoment}
            latestMoment={latestMoment}
            {...props}
          />
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
  maxStartDate: PropTypes.instanceOf(Date),
  maxEndDate: PropTypes.instanceOf(Date),
  onDatesChanged: PropTypes.func,
};
