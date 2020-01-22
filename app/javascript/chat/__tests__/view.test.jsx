import { h } from 'preact';
import render from 'preact-render-to-json';
import { deep } from 'preact-render-spy';
import View from '../view';

let exited = false;
let accepted = false;
let declined = false;

const onViewExitFake = () => {
  exited = true;
};

const handleInvitationAcceptFake = () => {
  accepted = true;
};

const handleInvitationDeclineFake = () => {
  declined = true;
};

const sampleChannel = [
  {
    channel_name: 'name',
    description: 'some description',
    membership_id: '12345',
  },
];

const getView = channel => (
  <View
    channels={channel}
    onViewExit={onViewExitFake}
    onAcceptInvitation={handleInvitationAcceptFake}
    onDeclineInvitation={handleInvitationDeclineFake}
  />
);

describe('<View />', () => {
  it('should render and test snapshot (no channel)', () => {
    const tree = render(getView([]));
    expect(tree).toMatchSnapshot();
  });

  it('should render and test snapshot (with channel)', () => {
    const tree = deep(getView(sampleChannel), { depth: 2 });
    expect(tree).toMatchSnapshot();
  });

  it('should have the proper attributes and text values (no channel provided)', () => {
    const context = deep(getView([]), { depth: 2 });
    expect(context.find('.chatNonChatView').exists()).toEqual(true);
    expect(context.find('.container').exists()).toEqual(true);

    expect(context.find('.chatNonChatView_exitbutton').exists()).toEqual(true);
    expect(context.find('.chatNonChatView_exitbutton').text()).toEqual('×');

    expect(context.find('h1').exists()).toEqual(true);
    expect(context.find('h1').text()).toEqual('Channel Invitations 🤗');

    expect(context.find('.chatNonChatView_contentblock').exists()).toEqual(
      false,
    );
  });

  it('should have the proper attributes and text values (with channel provided)', () => {
    const context = deep(getView(sampleChannel), { depth: 2 });
    expect(context.find('.chatNonChatView_contentblock').exists()).toEqual(
      true,
    );

    expect(context.find('h2').exists()).toEqual(true);
    expect(context.find('h2').text()).toEqual('name');

    expect(context.find('em').exists()).toEqual(true);
    expect(context.find('em').text()).toEqual('some description');

    expect(context.find('.cta').exists()).toEqual(true);
    expect(
      context
        .find('.cta')
        .at(0)
        .attr('data-content'),
    ).toEqual('12345'); // accept button
    expect(
      context
        .find('.cta')
        .at(0)
        .text(),
    ).toEqual('Accept'); // accept button
    expect(
      context
        .find('.cta')
        .at(1)
        .attr('data-content'),
    ).toEqual('12345'); // decline button
    expect(
      context
        .find('.cta')
        .at(1)
        .text(),
    ).toEqual('Decline'); // accept button
  });

  it('should trigger exit', () => {
    const context = deep(getView([]), { depth: 2 });
    context.find('.chatNonChatView_exitbutton').simulate('click');
    expect(exited).toEqual(true);
    exited = false;
  });

  it('should trigger accept', () => {
    const context = deep(getView(sampleChannel), { depth: 2 });
    context
      .find('.cta')
      .at(0)
      .simulate('click'); // click accept button

    expect(exited).toEqual(false);
    expect(accepted).toEqual(true);
    expect(declined).toEqual(false);

    accepted = false;
  });

  it('should trigger decline', () => {
    const context = deep(getView(sampleChannel), { depth: 2 });
    context
      .find('.cta')
      .at(1)
      .simulate('click'); // click decline button

    expect(exited).toEqual(false);
    expect(accepted).toEqual(false);
    expect(declined).toEqual(true);

    declined = false;
  });
});
