import { h } from 'preact';
import { render, waitFor, within } from '@testing-library/preact';
import userEvent from '@testing-library/user-event';
import {
  DateRangePicker,
  MONTH_UNTIL_TODAY,
  QUARTER_UNTIL_TODAY,
  YEAR_UNTIL_TODAY,
  LAST_FULL_MONTH,
  LAST_FULL_QUARTER,
  LAST_FULL_YEAR,
} from '@crayons';
import '@testing-library/jest-dom';

const windowNavigator = window.navigator;

describe('<DateRangePicker />', () => {
  const todayMock = new Date('2022-01-25');

  beforeAll(() => {
    global.window.matchMedia = jest.fn((query) => {
      return {
        matches: false,
        media: query,
        addListener: jest.fn(),
        removeListener: jest.fn(),
      };
    });
  });

  it('renders without default start and end dates', () => {
    const { getByRole, getAllByRole } = render(
      <DateRangePicker
        startDateId="start-date"
        endDateId="end-date"
        todaysDate={todayMock}
        minStartDate={new Date('2021-01-01')}
        maxEndDate={new Date('2022-06-01')}
      />,
    );

    expect(
      getByRole('textbox', {
        name: 'Start date (MM/DD/YYYY)',
      }),
    ).toHaveValue('');

    expect(getByRole('textbox', { name: 'End date (MM/DD/YYYY)' })).toHaveValue(
      '',
    );

    // react-dates renders a hidden (by CSS) month/year picker for off screen previous and next month views
    // testing library doesn't load the CSS, so we have to "skip over" the first matching select to get the correct visible one
    const monthPickers = getAllByRole('combobox', {
      name: 'Navigate to month',
    });
    expect(monthPickers).toHaveLength(4);
    expect(monthPickers[1]).toHaveDisplayValue('January');
    expect(monthPickers[2]).toHaveDisplayValue('February');
  });

  it('renders with a default start date', () => {
    const { getByRole, getAllByRole } = render(
      <DateRangePicker
        startDateId="start-date"
        endDateId="end-date"
        defaultStartDate={new Date('2022-01-01')}
        minStartDate={new Date('2021-01-01')}
      />,
    );

    expect(
      getByRole('textbox', {
        name: 'Start date (MM/DD/YYYY)',
      }),
    ).toHaveValue('01/01/2022');

    const monthPickers = getAllByRole('combobox', {
      name: 'Navigate to month',
    });
    // react-dates renders a hidden (by CSS) month/year picker for off screen previous and next month views
    // testing library doesn't load the CSS, so we have to "skip over" the first matching select to get the correct visible one
    expect(monthPickers).toHaveLength(4);
    expect(monthPickers[1]).toHaveDisplayValue('January');
    expect(monthPickers[2]).toHaveDisplayValue('February');

    const yearPickers = getAllByRole('combobox', { name: 'Navigate to year' });
    expect(yearPickers).toHaveLength(4);

    expect(yearPickers[1]).toHaveDisplayValue('2022');
    expect(yearPickers[2]).toHaveDisplayValue('2022');
  });

  it('renders with a default end date', () => {
    const { getByRole } = render(
      <DateRangePicker
        startDateId="start-date"
        endDateId="end-date"
        defaultEndDate={new Date('2022-01-01')}
      />,
    );

    expect(
      getByRole('textbox', {
        name: 'End date (MM/DD/YYYY)',
      }),
    ).toHaveValue('01/01/2022');
  });

  it('calls onDatesChanged when dates are selected', async () => {
    const onDatesChangedSpy = jest.fn();
    const { getByRole } = render(
      <DateRangePicker
        startDateId="start-date"
        endDateId="end-date"
        todaysDate={todayMock}
        minStartDate={new Date('2022-01-01')}
        maxEndDate={new Date('2022-01-31')}
        onDatesChanged={onDatesChangedSpy}
      />,
    );

    const startDateInput = getByRole('textbox', {
      name: 'Start date (MM/DD/YYYY)',
    });
    const endDateInput = getByRole('textbox', {
      name: 'End date (MM/DD/YYYY)',
    });

    userEvent.type(startDateInput, '01/25/2022');

    await waitFor(() =>
      expect(startDateInput).toHaveDisplayValue('01/25/2022'),
    );
    userEvent.type(endDateInput, '01/26/2022');
    await waitFor(() => expect(endDateInput).toHaveDisplayValue('01/26/2022'));

    // Called once for every keystroke
    await waitFor(() => expect(onDatesChangedSpy).toHaveBeenCalledTimes(20));
    const { startDate, endDate } = onDatesChangedSpy.mock.calls[19][0];

    expect(startDate.getDate()).toEqual(25);
    expect(startDate.getMonth()).toEqual(0);
    expect(startDate.getFullYear()).toEqual(2022);

    expect(endDate.getDate()).toEqual(26);
    expect(endDate.getMonth()).toEqual(0);
    expect(endDate.getFullYear()).toEqual(2022);
  });

  it('displays errors on blur if an invalid date is typed', async () => {
    const { getByRole } = render(
      <DateRangePicker
        startDateId="start-date"
        endDateId="end-date"
        todaysDate={todayMock}
        minStartDate={new Date('2022-01-01')}
        maxEndDate={new Date('2022-01-31')}
      />,
    );

    const startDateInput = getByRole('textbox', {
      name: 'Start date (MM/DD/YYYY)',
    });

    const endDateInput = getByRole('textbox', {
      name: 'End date (MM/DD/YYYY)',
    });

    userEvent.type(startDateInput, 'something');
    await waitFor(() => expect(startDateInput).toHaveDisplayValue('something'));
    // Move away from the input to trigger the blur event
    userEvent.tab();

    await waitFor(() =>
      expect(startDateInput).toHaveAccessibleDescription(
        'Start date must be in the format MM/DD/YYYY',
      ),
    );

    userEvent.type(endDateInput, '12345');
    await waitFor(() => expect(endDateInput).toHaveDisplayValue('12345'));
    userEvent.tab();

    await waitFor(() =>
      expect(endDateInput).toHaveAccessibleDescription(
        'End date must be in the format MM/DD/YYYY',
      ),
    );
  });

  it('displays errors on blur if date is before minimum date', async () => {
    const { getByRole } = render(
      <DateRangePicker
        startDateId="start-date"
        endDateId="end-date"
        todaysDate={todayMock}
        minStartDate={new Date('2022-01-01')}
        maxEndDate={new Date('2022-01-31')}
      />,
    );

    const startDateInput = getByRole('textbox', {
      name: 'Start date (MM/DD/YYYY)',
    });

    const endDateInput = getByRole('textbox', {
      name: 'End date (MM/DD/YYYY)',
    });

    userEvent.type(startDateInput, '01/22/2020');
    await waitFor(() =>
      expect(startDateInput).toHaveDisplayValue('01/22/2020'),
    );
    // Move away from the input to trigger the blur event
    userEvent.tab();

    await waitFor(() =>
      expect(startDateInput).toHaveAccessibleDescription(
        'Start date must be on or after 01/01/2022',
      ),
    );

    userEvent.type(endDateInput, '01/22/2020');
    await waitFor(() => expect(endDateInput).toHaveDisplayValue('01/22/2020'));
    userEvent.tab();

    await waitFor(() =>
      expect(endDateInput).toHaveAccessibleDescription(
        'End date must be on or after 01/01/2022',
      ),
    );
  });

  it('displays errors on blur if date is after maximum date', async () => {
    const { getByRole } = render(
      <DateRangePicker
        startDateId="start-date"
        endDateId="end-date"
        todaysDate={todayMock}
        minStartDate={new Date('2022-01-01')}
        maxEndDate={new Date('2022-01-31')}
      />,
    );

    const startDateInput = getByRole('textbox', {
      name: 'Start date (MM/DD/YYYY)',
    });

    const endDateInput = getByRole('textbox', {
      name: 'End date (MM/DD/YYYY)',
    });

    userEvent.type(startDateInput, '05/22/2022');
    await waitFor(() =>
      expect(startDateInput).toHaveDisplayValue('05/22/2022'),
    );
    // Move away from the input to trigger the blur event
    userEvent.tab();

    await waitFor(() =>
      expect(startDateInput).toHaveAccessibleDescription(
        'Start date must be on or before 01/31/2022',
      ),
    );

    userEvent.type(endDateInput, '05/22/2022');
    await waitFor(() => expect(endDateInput).toHaveDisplayValue('05/22/2022'));
    userEvent.tab();

    await waitFor(() =>
      expect(endDateInput).toHaveAccessibleDescription(
        'End date must be on or before 01/31/2022',
      ),
    );
  });

  it('skips to a selected year', async () => {
    const { getByRole, queryByRole, getAllByRole } = render(
      <DateRangePicker
        startDateId="start-date"
        endDateId="end-date"
        todaysDate={todayMock}
        minStartDate={new Date('2020-01-01')}
        maxEndDate={new Date('2022-06-02')}
      />,
    );

    expect(
      queryByRole('button', {
        name: 'Choose Monday, January 25, 2021 as start date',
      }),
    ).not.toBeInTheDocument();

    // react-dates renders a hidden (by CSS) month/year picker for off screen previous and next month views
    // testing library doesn't load the CSS, so we need to skip the first "hidden" select
    const startYearPicker = getAllByRole('combobox', {
      name: 'Navigate to year',
    })[1];
    userEvent.selectOptions(
      startYearPicker,
      within(startYearPicker).getByRole('option', { name: '2021' }),
    );

    await waitFor(() => expect(startYearPicker).toHaveDisplayValue('2021'));

    await waitFor(() =>
      expect(
        getByRole('button', {
          name: 'Choose Monday, January 25, 2021 as start date',
        }),
      ).toBeInTheDocument(),
    );
  });

  it('skips to a selected month', async () => {
    const { queryByRole, getByRole, getByDisplayValue } = render(
      <DateRangePicker
        startDateId="start-date"
        endDateId="end-date"
        todaysDate={todayMock}
        minStartDate={new Date('2021-01-01')}
        maxEndDate={new Date('2022-06-01')}
      />,
    );

    expect(
      queryByRole('button', {
        name: 'Choose Wednesday, April 6, 2022 as start date',
      }),
    ).not.toBeInTheDocument();

    // react-dates renders a hidden (by CSS) month/year picker for off screen previous and next month views
    // testing library doesn't load the CSS, so we grab the correct picker by displayValue rather than role/name
    const startMonthPicker = getByDisplayValue('January');

    userEvent.selectOptions(startMonthPicker, 'April');
    await waitFor(() => expect(startMonthPicker).toHaveDisplayValue('April'));

    await waitFor(() =>
      expect(
        getByRole('button', {
          name: 'Choose Wednesday, April 6, 2022 as start date',
        }),
      ).toBeInTheDocument(),
    );
  });

  it('disables navigation button if previous/next month is outside permitted dates', () => {
    const { getByRole } = render(
      <DateRangePicker
        startDateId="start-date"
        endDateId="end-date"
        todaysDate={todayMock}
        minStartDate={new Date('2022-01-01')}
        maxEndDate={new Date('2022-01-31')}
      />,
    );

    expect(
      getByRole('button', {
        name: 'Move forward to switch to the next month.',
      }),
    ).toHaveAttribute('aria-disabled', 'true');

    expect(
      getByRole('button', {
        name: 'Move backward to switch to the previous month.',
      }),
    ).toHaveAttribute('aria-disabled', 'true');
  });

  it('displays preset range buttons', () => {
    const { getByRole } = render(
      <DateRangePicker
        startDateId="start-date"
        endDateId="end-date"
        todaysDate={todayMock}
        minStartDate={new Date('2020-01-01')}
        maxEndDate={todayMock}
        presetRanges={[
          MONTH_UNTIL_TODAY,
          QUARTER_UNTIL_TODAY,
          YEAR_UNTIL_TODAY,
          LAST_FULL_MONTH,
          LAST_FULL_QUARTER,
          LAST_FULL_YEAR,
        ]}
      />,
    );
    expect(getByRole('button', { name: 'This month' })).toBeInTheDocument();
    expect(getByRole('button', { name: 'This quarter' })).toBeInTheDocument();
    expect(getByRole('button', { name: 'This year' })).toBeInTheDocument();
    expect(getByRole('button', { name: 'Last month' })).toBeInTheDocument();
    expect(getByRole('button', { name: 'Last quarter' })).toBeInTheDocument();
    expect(getByRole('button', { name: 'Last year' })).toBeInTheDocument();
  });

  it('does not display preset range buttons if outside permitted dates', () => {
    const { getByRole, queryByRole } = render(
      <DateRangePicker
        startDateId="start-date"
        endDateId="end-date"
        todaysDate={todayMock}
        minStartDate={new Date('2022-01-01')}
        maxEndDate={todayMock}
        presetRanges={[MONTH_UNTIL_TODAY, LAST_FULL_YEAR]}
      />,
    );
    expect(getByRole('button', { name: 'This month' })).toBeInTheDocument();
    expect(queryByRole('button', { name: 'Last year' })).toBeNull();
  });

  it('selects a preset range', async () => {
    const { getByRole } = render(
      <DateRangePicker
        startDateId="start-date"
        endDateId="end-date"
        todaysDate={todayMock}
        minStartDate={new Date('2022-01-01')}
        maxEndDate={todayMock}
        presetRanges={[MONTH_UNTIL_TODAY]}
      />,
    );

    getByRole('button', { name: 'This month' }).click();

    await waitFor(() =>
      expect(
        getByRole('textbox', { name: 'Start date (MM/DD/YYYY)' }),
      ).toHaveDisplayValue('01/01/2022'),
    );
    expect(
      getByRole('textbox', { name: 'End date (MM/DD/YYYY)' }),
    ).toHaveDisplayValue('01/25/2022');
  });

  describe('Localization', () => {
    afterAll(() => {
      Object.defineProperty(window, 'navigator', {
        value: windowNavigator,
        writable: true,
      });
    });

    it('localizes for en-US date format', async () => {
      Object.defineProperty(window, 'navigator', {
        value: { language: 'en-US' },
        writable: true,
      });

      const { getAllByPlaceholderText, getByRole, getByDisplayValue } = render(
        <DateRangePicker
          startDateId="start-date"
          endDateId="end-date"
          minStartDate={new Date('2020-01-01')}
          maxEndDate={new Date('2020-01-31')}
          todaysDate={new Date('2020-01-31')}
        />,
      );

      const inputs = getAllByPlaceholderText('MM/DD/YYYY');
      expect(inputs).toHaveLength(2);

      getByRole('button', {
        name: 'Interact with the calendar and add your start date',
      }).click();

      getByRole('button', {
        name: 'Choose Wednesday, January 22, 2020 as start date',
      }).click();

      await waitFor(() =>
        expect(getByDisplayValue('01/22/2020')).toBeInTheDocument(),
      );
    });

    it('localizes for non en-US format', async () => {
      Object.defineProperty(window, 'navigator', {
        value: { language: 'en' },
        writable: true,
      });

      const { getAllByPlaceholderText, getByRole, getByDisplayValue } = render(
        <DateRangePicker
          startDateId="start-date"
          endDateId="end-date"
          minStartDate={new Date('2020-01-01')}
          maxEndDate={new Date('2020-01-31')}
          todaysDate={new Date('2020-01-31')}
        />,
      );

      expect(getAllByPlaceholderText('DD/MM/YYYY')).toHaveLength(2);

      getByRole('button', {
        name: 'Interact with the calendar and add your start date',
      }).click();

      getByRole('button', {
        name: 'Choose Wednesday, January 22, 2020 as start date',
      }).click();

      await waitFor(() =>
        expect(getByDisplayValue('22/01/2020')).toBeInTheDocument(),
      );
    });
  });
});
