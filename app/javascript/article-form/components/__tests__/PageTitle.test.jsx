import { h } from 'preact';
import { render } from '@testing-library/preact';
import { axe } from 'jest-axe';
import { PageTitle } from '../PageTitle';
import '@testing-library/jest-dom';

let organizations, organizationId, onToggle;

describe('<PageTitle/>', () => {
  beforeEach(() => {
    organizations = [
      {
        id: 4,
        bg_color_hex: '',
        name: 'DEV',
        text_color_hex: '',
        profile_image_90:
          '/uploads/organization/profile_image/4/1689e7ae-6306-43cd-acba-8bde7ed80a17.JPG',
      },
    ];

    organizationId = null;
    onToggle = null;
  });

  it('should have no a11y violations', async () => {
    const { container } = render(
      <PageTitle
        organizations={organizations}
        organizationId={organizationId}
        onToggle={onToggle}
      />,
    );
    const results = await axe(container);

    expect(results).toHaveNoViolations();
  });

  it('shows the picker if there is more than one organisation', () => {
    const { getByRole } = render(
      <PageTitle
        organizations={organizations}
        organizationId={organizationId}
        onToggle={onToggle}
      />,
    );

    expect(
      getByRole('combobox', { name: /select an organization/i }),
    ).toBeInTheDocument();
  });

  it('does not show the picker if there is no organisations', () => {
    const { queryByRole } = render(
      <PageTitle
        organizations={[]}
        organizationId={organizationId}
        onToggle={onToggle}
      />,
    );

    expect(
      queryByRole('combobox', { name: /select an organization/i }),
    ).not.toBeInTheDocument();
  });
});
