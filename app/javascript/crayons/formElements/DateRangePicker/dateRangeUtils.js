export const MONTH_UNTIL_TODAY = 'MONTH_UNTIL_TODAY';
export const QUARTER_UNTIL_TODAY = 'QUARTER_UNTIL_TODAY';
export const YEAR_UNTIL_TODAY = 'YEAR_UNTIL_TODAY';
export const LAST_FULL_MONTH = 'LAST_FULL_MONTH';
export const LAST_FULL_QUARTER = 'LAST_FULL_QUARTER';
export const LAST_FULL_YEAR = 'LAST_FULL_YEAR';

export const ALL_PRESET_RANGES = [
  MONTH_UNTIL_TODAY,
  LAST_FULL_MONTH,
  QUARTER_UNTIL_TODAY,
  LAST_FULL_QUARTER,
  YEAR_UNTIL_TODAY,
  LAST_FULL_YEAR,
];

export const RANGE_LABELS = {
  MONTH_UNTIL_TODAY: 'This month',
  QUARTER_UNTIL_TODAY: 'This quarter',
  YEAR_UNTIL_TODAY: 'This year',
  LAST_FULL_MONTH: 'Last month',
  LAST_FULL_QUARTER: 'Last quarter',
  LAST_FULL_YEAR: 'Last year',
};

const PERIODS = {
  DAY: 'day',
  MONTH: 'month',
  QUARTER: 'quarter',
  YEAR: 'year',
};

const getPeriodUntilToday = (today, period) => ({
  start: today.clone().startOf(period),
  end: today.clone(),
});

const getLastFullPeriod = (today, period) => ({
  start: today.clone().subtract(1, period).startOf(period),
  end: today.clone().subtract(1, period).endOf(period),
});

export const getDateRangeStartAndEndDates = ({ today, dateRangeName }) => {
  switch (dateRangeName) {
    case MONTH_UNTIL_TODAY:
      return getPeriodUntilToday(today, PERIODS.MONTH);
    case LAST_FULL_MONTH:
      return getLastFullPeriod(today, PERIODS.MONTH);
    case QUARTER_UNTIL_TODAY:
      return getPeriodUntilToday(today, PERIODS.QUARTER);
    case LAST_FULL_QUARTER:
      return getLastFullPeriod(today, PERIODS.QUARTER);
    case YEAR_UNTIL_TODAY:
      return getPeriodUntilToday(today, PERIODS.YEAR);
    case LAST_FULL_YEAR:
      return getLastFullPeriod(today, PERIODS.YEAR);
  }
};
