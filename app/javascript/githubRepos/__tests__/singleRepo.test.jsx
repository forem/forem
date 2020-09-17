import { h } from 'preact';
import { render } from '@testing-library/preact';
import fetch from 'jest-fetch-mock';
import { axe } from 'jest-axe';
import { SingleRepo } from '../singleRepo';

global.fetch = fetch;

describe('<SingleRepo />', () => {
  it('should have no a11y violations', async () => {
    const { container } = render(
      <SingleRepo
        githubIdCode={123}
        name="dev.to"
        fork={false}
        featured={false}
      />,
    );
    const results = await axe(container);

    expect(results).toHaveNoViolations();
  });

  it('should render as not featured', () => {
    const { getByText, queryByText } = render(
      <SingleRepo
        githubIdCode={123}
        name="dev.to"
        fork={false}
        featured={false}
      />,
    );

    getByText('dev.to');
    getByText('SELECT');

    const removeButton = queryByText('REMOVE');

    expect(removeButton).toBeNull();
  });

  it('should render as featured', () => {
    const { getByText, queryByText } = render(
      <SingleRepo githubIdCode={123} name="dev.to" fork={false} featured />,
    );

    getByText('dev.to');
    getByText('REMOVE');

    const selectButton = queryByText('SELECT');

    expect(selectButton).toBeNull();
  });

  it('should render as a forked repository', () => {
    const { getByText, queryByText } = render(
      <SingleRepo githubIdCode={123} name="dev.to" fork featured={false} />,
    );

    getByText('dev.to');
    getByText('SELECT');
    getByText('fork');

    const removeButton = queryByText('REMOVE');

    expect(removeButton).toBeNull();
  });
});
