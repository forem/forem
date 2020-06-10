import { h } from 'preact';
import render from 'preact-render-to-json';
import { shallow } from 'preact-render-spy';
import InviteForm from '../ChatChannelSettings/InviateForm';

const data = {
  invitationUsernames: ''
}

const getInviteForm = (invitations) => (
  <InviteForm 
    invitationUsernames={invitations.invitationUsernames}
  />
)

describe('<InviteForm />', () => {
  it("should render the test snapshot", () => {
    const tree = render(getInviteForm(data))
    expect(tree).toMatchSnapshot();
  })

  it("should have the element", () => {
    const context = shallow(getInviteForm(data));

    expect(context.find('.invitation_form_title').exists()).toEqual(true)
  })
})