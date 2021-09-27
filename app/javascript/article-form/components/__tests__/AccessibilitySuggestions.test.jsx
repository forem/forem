import { h } from 'preact';
import { render } from '@testing-library/preact';
import { axe } from 'jest-axe';
import '@testing-library/jest-dom';
import { AccessibilitySuggestions } from '../AccessibilitySuggestions';

describe('<AccessibilitySuggestions />', () => {
  it('should have no a11y violations', async () => {
    const { container } = render(
      <AccessibilitySuggestions
        markdownLintErrors={[
          {
            errorDetail: '/detailUrl',
            ruleNames: ['example-rule'],
            errorContext: 'Example suggestion',
          },
        ]}
      />,
    );

    const results = await axe(container);
    expect(results).toHaveNoViolations();
  });

  it('should display a list of maximum 3 suggestions', () => {
    const lintErrors = [1, 2, 3, 4].map((item) => ({
      errorDetail: '/detailUrl',
      ruleNames: ['no-empty-alt-text'],
      errorContext: `Suggestion ${item}`,
    }));

    const { getAllByRole, getByText, queryByText } = render(
      <AccessibilitySuggestions markdownLintErrors={lintErrors} />,
    );

    const listItems = getAllByRole('listitem');
    expect(listItems).toHaveLength(3);
    expect(getByText('Suggestion 1')).toBeInTheDocument();
    expect(getByText('Suggestion 2')).toBeInTheDocument();
    expect(getByText('Suggestion 3')).toBeInTheDocument();
    expect(queryByText('Suggestion 4')).not.toBeInTheDocument();

    const detailLinks = getAllByRole('link', {
      name: 'Learn more about accessible images',
    });
    expect(detailLinks).toHaveLength(3);
  });

  it('should only show image errors if there are 3 or more', () => {
    const imageErrors = [
      {
        errorDetail: '/detailUrl',
        ruleNames: ['no-empty-alt-text'],
        errorContext: 'No empty alt text 1',
      },
      {
        errorDetail: '/detailUrl',
        ruleNames: ['no-default-alt-text'],
        errorContext: 'No default alt text 1',
      },
      {
        errorDetail: '/detailUrl',
        ruleNames: ['no-empty-alt-text'],
        errorContext: 'No empty alt text 2',
      },
    ];

    const otherErrors = [
      {
        errorDetail: '/detailUrl',
        ruleNames: ['other'],
        errorContext: 'Other 1',
      },
      {
        errorDetail: '/detailUrl',
        ruleNames: ['other'],
        errorContext: 'Other 2',
      },
    ];

    const { getAllByRole, getByText, queryByText } = render(
      <AccessibilitySuggestions
        markdownLintErrors={[...otherErrors, ...imageErrors]}
      />,
    );

    const listItems = getAllByRole('listitem');
    expect(listItems).toHaveLength(3);
    imageErrors.forEach((imageError) => {
      expect(getByText(imageError.errorContext)).toBeInTheDocument();
    });

    const imageDetailLinks = getAllByRole('link', {
      name: 'Learn more about accessible images',
    });
    expect(imageDetailLinks).toHaveLength(3);

    otherErrors.forEach((otherError) => {
      expect(queryByText(otherError.errorContext)).not.toBeInTheDocument();
    });
  });

  it('should show other errors if there are fewer than 3 image errors', () => {
    const imageErrors = [
      {
        errorDetail: '/detailUrl',
        ruleNames: ['no-empty-alt-text'],
        errorContext: 'No empty alt text 1',
      },
      {
        errorDetail: '/detailUrl',
        ruleNames: ['no-default-alt-text'],
        errorContext: 'No default alt text 1',
      },
    ];

    const otherErrors = [
      {
        errorDetail: '/detailUrl',
        ruleNames: ['other'],
        errorContext: 'Other 1',
      },
      {
        errorDetail: '/detailUrl',
        ruleNames: ['other'],
        errorContext: 'Other 2',
      },
    ];

    const { getAllByRole, getByText, queryByText } = render(
      <AccessibilitySuggestions
        markdownLintErrors={[...otherErrors, ...imageErrors]}
      />,
    );

    const listItems = getAllByRole('listitem');
    expect(listItems).toHaveLength(3);
    imageErrors.forEach((imageError) => {
      expect(getByText(imageError.errorContext)).toBeInTheDocument();
    });

    expect(
      getAllByRole('link', {
        name: 'Learn more about accessible images',
      }),
    ).toHaveLength(2);

    expect(getByText('Other 1')).toBeInTheDocument();
    expect(queryByText('Other 2')).not.toBeInTheDocument();

    expect(
      getAllByRole('link', {
        name: 'Learn more about accessible headings',
      }),
    ).toHaveLength(1);
  });
});
