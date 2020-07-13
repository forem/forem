import { h } from 'preact';
import { render } from '@testing-library/preact';
import { axe } from 'jest-axe';
import { OrganizationPicker } from '../OrganizationPicker';

const commonProps = {
  id: 'someFormElementId',
  name: 'someFormElementName',
  onToggle: jest.fn(),
};

const organizations = [
  { id: 1, name: 'Acme Org 1' },
  { id: 2, name: 'Acme Org 2' },
];

describe('<OrganizationPicker />', () => {
  it('should have no a11y violations', async () => {
    const { container } = render(
      <OrganizationPicker
        {...commonProps}
        organizationId={1}
        organizations={organizations}
      />,
    );
    const results = await axe(container);

    expect(results).toHaveNoViolations();
  });

  it('renders with the given organization selected from the list of available organizations', () => {
    const { getByText } = render(
      <OrganizationPicker
        {...commonProps}
        organizationId={1}
        organizations={organizations}
      />,
    );

    getByText('Acme Org 1');
    getByText('Acme Org 2');
    expect(getByText('Acme Org 1').selected).toEqual(true);
  });

  it('renders with no organization selected when the organization ID is not set', () => {
    const { getByText } = render(
      <OrganizationPicker
        {...commonProps}
        organizationId={undefined}
        organizations={organizations}
      />,
    );

    getByText('Acme Org 1');
    getByText('Acme Org 2');
    expect(getByText('Acme Org 1').selected).toEqual(false);
    expect(getByText('Acme Org 2').selected).toEqual(false);
  });

  it('renders an organization list with only "None" as an option when no organizations are passed in.', () => {
    const { queryByText } = render(
      <OrganizationPicker
        {...commonProps}
        organizationId={undefined}
        organizations={[]}
      />,
    );

    expect(queryByText('None')).toBeDefined();
  });
});
