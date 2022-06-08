import moment from 'moment';
import {
  getDateRangeStartAndEndDates,
  MONTH_UNTIL_TODAY,
  LAST_FULL_MONTH,
  QUARTER_UNTIL_TODAY,
  LAST_FULL_QUARTER,
  YEAR_UNTIL_TODAY,
  LAST_FULL_YEAR,
} from '../dateRangeUtils';

describe('dateRangeUtils', () => {
  const mockToday = moment('2022-03-12');

  it('returns start and end moments for current month til today', () => {
    const { start, end } = getDateRangeStartAndEndDates({
      today: mockToday,
      dateRangeName: MONTH_UNTIL_TODAY,
    });

    expect(start.month()).toEqual(2);
    expect(start.date()).toEqual(1);
    expect(start.year()).toEqual(2022);

    expect(end.month()).toEqual(2);
    expect(end.date()).toEqual(12);
    expect(end.year()).toEqual(2022);
  });

  it('returns start and end moments for current year til today', () => {
    const { start, end } = getDateRangeStartAndEndDates({
      today: mockToday,
      dateRangeName: YEAR_UNTIL_TODAY,
    });

    expect(start.month()).toEqual(0);
    expect(start.date()).toEqual(1);
    expect(start.year()).toEqual(2022);

    expect(end.month()).toEqual(2);
    expect(end.date()).toEqual(12);
    expect(end.year()).toEqual(2022);
  });

  describe('Last full calendar month', () => {
    it('returns start and end moments when today is middle of month', () => {
      const { start, end } = getDateRangeStartAndEndDates({
        today: mockToday,
        dateRangeName: LAST_FULL_MONTH,
      });

      expect(start.month()).toEqual(1);
      expect(start.date()).toEqual(1);
      expect(start.year()).toEqual(2022);

      expect(end.month()).toEqual(1);
      expect(end.date()).toEqual(28);
      expect(end.year()).toEqual(2022);
    });

    it('returns start and end moments when today is last day of month', () => {
      const today = moment('2022-01-31');
      const { start, end } = getDateRangeStartAndEndDates({
        today,
        dateRangeName: LAST_FULL_MONTH,
      });

      expect(start.month()).toEqual(11);
      expect(start.date()).toEqual(1);
      expect(start.year()).toEqual(2021);

      expect(end.month()).toEqual(11);
      expect(end.date()).toEqual(31);
      expect(end.year()).toEqual(2021);
    });

    it('returns start and end moments across months with different day numbers', () => {
      const today = moment('2022-02-12');
      const { start, end } = getDateRangeStartAndEndDates({
        today,
        dateRangeName: LAST_FULL_MONTH,
      });

      expect(start.month()).toEqual(0);
      expect(start.date()).toEqual(1);
      expect(start.year()).toEqual(2022);

      expect(end.month()).toEqual(0);
      expect(end.date()).toEqual(31);
      expect(end.year()).toEqual(2022);
    });
  });

  describe('Quarter til today', () => {
    it('returns start and end moments for date in Q1', () => {
      const { start, end } = getDateRangeStartAndEndDates({
        today: mockToday,
        dateRangeName: QUARTER_UNTIL_TODAY,
      });

      expect(start.month()).toEqual(0);
      expect(start.date()).toEqual(1);
      expect(start.year()).toEqual(2022);

      expect(end.month()).toEqual(2);
      expect(end.date()).toEqual(12);
      expect(end.year()).toEqual(2022);
    });

    it('returns start and end moments for date in Q2', () => {
      const today = moment('2021-05-05');

      const { start, end } = getDateRangeStartAndEndDates({
        today,
        dateRangeName: QUARTER_UNTIL_TODAY,
      });

      expect(start.month()).toEqual(3);
      expect(start.date()).toEqual(1);
      expect(start.year()).toEqual(2021);

      expect(end.month()).toEqual(4);
      expect(end.date()).toEqual(5);
      expect(end.year()).toEqual(2021);
    });

    it('returns start and end moments for date in Q3', () => {
      const today = moment('2021-08-05');

      const { start, end } = getDateRangeStartAndEndDates({
        today,
        dateRangeName: QUARTER_UNTIL_TODAY,
      });

      expect(start.month()).toEqual(6);
      expect(start.date()).toEqual(1);
      expect(start.year()).toEqual(2021);

      expect(end.month()).toEqual(7);
      expect(end.date()).toEqual(5);
      expect(end.year()).toEqual(2021);
    });

    it('returns start and end moments for date in Q4', () => {
      const today = moment('2021-12-05');

      const { start, end } = getDateRangeStartAndEndDates({
        today,
        dateRangeName: QUARTER_UNTIL_TODAY,
      });

      expect(start.month()).toEqual(9);
      expect(start.date()).toEqual(1);
      expect(start.year()).toEqual(2021);

      expect(end.month()).toEqual(11);
      expect(end.date()).toEqual(5);
      expect(end.year()).toEqual(2021);
    });
  });

  describe('Last full quarter', () => {
    it('returns start and end moments when today is last day of a quarter', () => {
      const today = moment('2022-06-30');
      const { start, end } = getDateRangeStartAndEndDates({
        today,
        dateRangeName: LAST_FULL_QUARTER,
      });

      expect(start.month()).toEqual(0);
      expect(start.date()).toEqual(1);
      expect(start.year()).toEqual(2022);

      expect(end.month()).toEqual(2);
      expect(end.date()).toEqual(31);
      expect(end.year()).toEqual(2022);
    });

    it('returns start and end moments when today is in the middle of a quarter', () => {
      const { start, end } = getDateRangeStartAndEndDates({
        today: mockToday,
        dateRangeName: LAST_FULL_QUARTER,
      });

      expect(start.month()).toEqual(9);
      expect(start.date()).toEqual(1);
      expect(start.year()).toEqual(2021);

      expect(end.month()).toEqual(11);
      expect(end.date()).toEqual(31);
      expect(end.year()).toEqual(2021);
    });
  });

  describe('Last full year', () => {
    it('returns start and end moments when today is last day of a year', () => {
      const today = moment('2022-12-31');
      const { start, end } = getDateRangeStartAndEndDates({
        today,
        dateRangeName: LAST_FULL_YEAR,
      });

      expect(start.month()).toEqual(0);
      expect(start.date()).toEqual(1);
      expect(start.year()).toEqual(2021);

      expect(end.month()).toEqual(11);
      expect(end.date()).toEqual(31);
      expect(end.year()).toEqual(2021);
    });

    it('returns start and end moments when today is in the middle of a year', () => {
      const { start, end } = getDateRangeStartAndEndDates({
        today: mockToday,
        dateRangeName: LAST_FULL_YEAR,
      });

      expect(start.month()).toEqual(0);
      expect(start.date()).toEqual(1);
      expect(start.year()).toEqual(2021);

      expect(end.month()).toEqual(11);
      expect(end.date()).toEqual(31);
      expect(end.year()).toEqual(2021);
    });
  });
});
