import { h } from 'preact';
import { render } from '@testing-library/preact';
import { axe } from 'jest-axe';
import ReportAbuse from '../ReportAbuse';

describe('<ReportAbuse />', () => {
  it('should have no a11y violations', async () => {
    const { container } = render(
      <ReportAbuse
        data={{
          message: 'HI',
          user_id: 1,
        }}
      />,
    );
    const results = await axe(container);

    expect(results).toHaveNoViolations();
  });

  it('should render the component', () => {
    const { queryByText, getByTestId } = render(
      <ReportAbuse data={{ message: 'HI', user_id: 1 }} />,
    );

    expect(queryByText('Report Abuse')).toBeDefined();

    const vulgarInput = getByTestId('rude_or_vulgar');
    expect(vulgarInput.value).toEqual('rude or vulgar');

    const harassmentInput = getByTestId('harassment');
    expect(harassmentInput.value).toEqual('harassment');

    const listingsInput = getByTestId('listings');
    expect(listingsInput.value).toEqual('listings');

    const spamInput = getByTestId('spam');
    expect(spamInput.value).toEqual('spam');

    expect(queryByText('Report Message')).toBeDefined();
  });
});
