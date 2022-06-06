import { h } from 'preact';
import {
  LAST_FULL_MONTH,
  LAST_FULL_QUARTER,
  LAST_FULL_YEAR,
  QUARTER_UNTIL_TODAY,
  YEAR_UNTIL_TODAY,
} from '../dateRangeUtils';
import { DateRangePicker } from '@crayons';

export default {
  component: DateRangePicker,
  title: 'BETA/DateRangePicker',
  argTypes: {
    startDateId: {
      description: 'A unique identifier for the start date input (required)',
    },
    endDateId: {
      description: 'A unique identifier for the end date input (required)',
    },
    defaultStartDate: {
      description: 'A default value for the start date of the range (optional)',
      control: 'date',
    },
    defaultEndDate: {
      description: 'The default value for the end date of the range (optional)',
      control: 'date',
    },
    minStartDate: {
      description: 'The earliest date that may be selected',
      control: 'date',
      table: { defaultValue: { summary: 'Today' } },
    },
    maxEndDate: {
      description: 'The latest date that may be selected',
      control: 'date',
      table: { defaultValue: { summary: 'Today' } },
    },
    onDatesChanged: {
      description:
        'A callback function for when dates are selected. It receives an object with startDate and endDate values.',
    },
    presetRanges: {
      description:
        'Quick select buttons to display. These will only be displayed if they fall within the max and min date range set.',
      control: 'check',
      options: [
        LAST_FULL_MONTH,
        LAST_FULL_QUARTER,
        LAST_FULL_YEAR,
        QUARTER_UNTIL_TODAY,
        YEAR_UNTIL_TODAY,
      ],
    },
  },
};

export const Default = (args) => {
  return <DateRangePicker {...args} />;
};

Default.args = {
  startDateId: 'start-date',
  endDateId: 'end-date',
  defaultStartDate: undefined,
  defaultEndDate: undefined,
  minStartDate: new Date(2020, 0, 1),
  maxEndDate: new Date(),
  presetRanges: [],
};
