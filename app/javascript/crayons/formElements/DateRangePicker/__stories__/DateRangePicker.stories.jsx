import { h } from 'preact';
import { DateRangePicker } from '@crayons';

export default {
  component: DateRangePicker,
  title: 'components/Form Elements/DateRangePicker',
  argTypes: {
    startDateId: {
      description: 'A unique identifier for the start date input',
    },
    endDateId: {
      description: 'A unique identifier for the end date input',
    },
    defaultStartDate: {
      description:
        'The initial value of the start date of the range (optional)',
      control: 'date',
    },
    defaultEndDate: {
      description: 'The initial value of the end date of the range (optional)',
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
        'Callback function for when dates are selected. Receives an object with startDate and endDate values.',
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
