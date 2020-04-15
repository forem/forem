import { h } from 'preact';
import { deep } from 'preact-render-spy';
import ContactViaConnect from '../elements/contactViaConnect';

describe('<ContactViaConnect />', () => {
  const defaultProps = {
    onChange: () => {
      return 'onChange';
    },
    checked: true,
  };

  const renderContactViaConnect = (props = defaultProps) =>
    deep(<ContactViaConnect {...props} />);

  it('Should render a label with a message about chat via app', () => {
    const context = renderContactViaConnect();
    const label = context.find('#label-contact-via-connect');

    expect(label.text()).toBe(
      'Allow Users to Message Me Via In-App Chat (DEV Connect)',
    );
  });

  it('should render a checkbox', () => {
    const context = renderContactViaConnect();
    const input = context.find('#contact_via_connect');

    expect(input.attr('checked')).toBe(defaultProps.checked);
  });
});
