import { h } from 'preact';
import { render, queryByAttribute } from '@testing-library/preact';
import { axe } from 'jest-axe';
import { PageTitle } from '../PageTitle';

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
    const getById = queryByAttribute.bind(null, 'id');
    const dom = render(
      <PageTitle
        organizations={organizations}
        organizationId={organizationId}
        onToggle={onToggle}
      />,
    );

    const organizationPicker = getById(
      dom.container,
      'article_publish_under_org',
    );
    expect(organizationPicker).toBeTruthy();
  });

  it('does not show the picker if there is no organisations', () => {
    const getById = queryByAttribute.bind(null, 'id');
    const dom = render(
      <PageTitle
        organizations={[]}
        organizationId={organizationId}
        onToggle={onToggle}
      />,
    );

    const organizationPicker = getById(
      dom.container,
      'article_publish_under_org',
    );
    expect(organizationPicker).toBeNull();
  });
});
