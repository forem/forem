import { h } from 'preact';
import { shallow } from 'preact-render-spy';
import { PageTitle } from '../PageTitle';

let organizations; let organizationId; let onToggle;

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

  it('shows the picker if there is more than one organisation', () => {
    const container = shallow(
      <PageTitle
        organizations={organizations}
        organizationId={organizationId}
        onToggle={onToggle}
      />,
    );
    expect(container.find('#article_publish_under_org').exists()).toEqual(true);
  });

  it('does not show the picker if there is no organisations', () => {
    organizations = [];
    const container = shallow(
      <PageTitle
        organizations={organizations}
        organizationId={organizationId}
        onToggle={onToggle}
      />,
    );
    expect(container.find('#article_publish_under_org').exists()).toEqual(
      false,
    );
  });
});
