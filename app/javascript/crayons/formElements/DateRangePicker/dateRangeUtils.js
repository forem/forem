export const MONTH_UNTIL_TODAY = 'MONTH_UNTIL_TODAY';
export const QUARTER_UNTIL_TODAY = 'QUARTER_UNTIL_TODAY';
export const YEAR_UNTIL_TODAY = 'YEAR_UNTIL_TODAY';
export const LAST_FULL_MONTH = 'LAST_FULL_MONTH';
export const LAST_FULL_QUARTER = 'LAST_FULL_QUARTER';
export const LAST_FULL_YEAR = 'LAST_FULL_YEAR';

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

const getLastFullCalendarMonth = (today) => {
  const start = today.clone().startOf(PERIODS.MONTH);
  const end = today.clone().endOf(PERIODS.MONTH);

  const isTodayLastDayOfMonth = end.isSame(today.endOf(PERIODS.DAY));

  if (!isTodayLastDayOfMonth) {
    start.subtract(1, PERIODS.MONTH);
    end.subtract(1, PERIODS.MONTH).endOf(PERIODS.MONTH);
  }

  return { start, end };
};

const getLastFullQuarter = (today) => {
  const start = today.clone();
  const end = today.clone().endOf(PERIODS.QUARTER);
  const isTodayEndOfQuarter = end.isSame(today.endOf(PERIODS.DAY));

  if (!isTodayEndOfQuarter) {
    start.subtract(1, PERIODS.QUARTER);
    end.subtract(1, PERIODS.QUARTER);
  }

  return {
    start: start.startOf(PERIODS.QUARTER),
    end: end.endOf(PERIODS.QUARTER),
  };
};

const getLastFullYear = (today) => {
  const start = today.clone().startOf(PERIODS.YEAR);
  const end = today.clone().endOf(PERIODS.YEAR);
  const isTodayEndOfYear = end.isSame(today.endOf(PERIODS.DAY));

  if (!isTodayEndOfYear) {
    start.subtract(1, PERIODS.YEAR);
    end.subtract(1, PERIODS.YEAR);
  }

  return { start: start.startOf(PERIODS.YEAR), end: end.endOf(PERIODS.YEAR) };
};

export const getDateRangeStartAndEndDates = ({ today, dateRangeName }) => {
  switch (dateRangeName) {
    case MONTH_UNTIL_TODAY:
      return getPeriodUntilToday(today, PERIODS.MONTH);
    case LAST_FULL_MONTH:
      return getLastFullCalendarMonth(today);
    case QUARTER_UNTIL_TODAY:
      return getPeriodUntilToday(today, PERIODS.QUARTER);
    case LAST_FULL_QUARTER:
      return getLastFullQuarter(today);
    case YEAR_UNTIL_TODAY:
      return getPeriodUntilToday(today, PERIODS.YEAR);
    case LAST_FULL_YEAR:
      return getLastFullYear(today);
  }
};
