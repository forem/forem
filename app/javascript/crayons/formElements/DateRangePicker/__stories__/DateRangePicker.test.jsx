import { h } from 'preact';
import { render, waitFor } from '@testing-library/preact';
import { DateRangePicker } from '@crayons';
import '@testing-library/jest-dom';

const windowNavigator = window.navigator;

describe('<DateRangePicker />', () => {
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
          minStartDate={new Date(2020, 0, 1)}
          maxEndDate={new Date(2020, 0, 31)}
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
          minStartDate={new Date(2020, 0, 1)}
          maxEndDate={new Date(2020, 0, 31)}
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
