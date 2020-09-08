import { h } from 'preact';
import { axe } from 'jest-axe';
import { render } from '@testing-library/preact';
import '@testing-library/jest-dom';
import DateTime from '../dateTime';

global.window.timestampToLocalDateTimeLong = () =>
  'Sunday, 6 September, 2020, 7:45:02 pm';
global.window.timestampToLocalDateTimeShort = () => '6 Sep';

describe('<DateTime />', () => {
  it('should have no a11y violations', async () => {
    const { container } = render(
      <DateTime className={'date-time'} dateTime={new Date('2-2-2222')} />,
    );
    const results = await axe(container);

    expect(results).toHaveNoViolations();
  });

  it('should render given datetime', () => {
    const { getByTestId } = render(
      <DateTime className={'date-time'} dateTime={new Date('2-2-2222')} />,
    );

    const dateTime = getByTestId('date-time-formatting');

    expect(dateTime).toHaveTextContent('6 Sep');
    expect(dateTime.title).toBe('Sunday, 6 September, 2020, 7:45:02 pm');
    expect(dateTime.title).toBe('Sunday, 6 September, 2020, 7:45:02 pm');
    expect(dateTime).toHaveClass('date-time');
  });
});
