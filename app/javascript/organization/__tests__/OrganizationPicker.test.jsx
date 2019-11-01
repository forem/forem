import { h } from 'preact';
import render from 'preact-render-to-json';
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
  it('renders with the given organization selected from the list of available organizations', () => {
    const tree = render(
      <OrganizationPicker
        {...commonProps}
        organizationId={1}
        organizations={organizations}
      />,
    );
    expect(tree).toMatchSnapshot();
  });

  it('renders with no organization selected when the organization ID is not set', () => {
    const tree = render(
      <OrganizationPicker
        {...commonProps}
        organizationId={undefined}
        organizations={organizations}
      />,
    );
    expect(tree).toMatchSnapshot();
  });

  it('renders an organization list with only "None" as an option when no organizations are passed in.', () => {
    const tree = render(
      <OrganizationPicker
        {...commonProps}
        organizationId={undefined}
        organizations={[]}
      />,
    );
    expect(tree).toMatchSnapshot();
  });
});
