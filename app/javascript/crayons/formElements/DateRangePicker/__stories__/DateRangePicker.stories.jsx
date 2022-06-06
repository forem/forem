import { h } from 'preact';
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
};
