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
    const { getByText, getByLabelText } = render(
      <ReportAbuse data={{ message: 'HI', user_id: 1 }} />,
    );

    expect(getByText('Report Abuse')).toBeDefined();

    const vulgarInput = getByLabelText('Rude or vulgar');
    expect(vulgarInput.value).toEqual('rude or vulgar');

    const harassmentInput = getByLabelText('Harassment or hate speech');
    expect(harassmentInput.value).toEqual('harassment');

    const listingsInput = getByLabelText(
      'Inappropriate listings message/category',
    );
    expect(listingsInput.value).toEqual('listings');

    const spamInput = getByLabelText('Spam or copyright issue');
    expect(spamInput.value).toEqual('spam');

    expect(getByText('Report Message')).toBeDefined();
  });
});
