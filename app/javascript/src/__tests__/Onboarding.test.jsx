import { h } from 'preact';
import { shallow, deep } from 'preact-render-spy';
import fetch from 'jest-fetch-mock';
import Onboarding from '../Onboarding';

global.fetch = fetch;

// process.on('unhandledRejection', (reason, p) => {
//   console.log('Unhandled Rejection at: Promise', p, 'reason:', reason);
//   // application specific logging, throwing an error, or other logic here
// });

describe('<Onboarding />', () => {
  afterEach(() => {
    document.body.setAttribute('data-user', null);
  });

  const fakeResponse = JSON.stringify([{
    bg_color_hex: '#000000',
    id: 715,
    name: 'discuss',
    text_color_hex: '#ffffff',
  }, {
    bg_color_hex: '#f7df1e',
    id: 6,
    name: 'javascript',
    text_color_hex: '#000000',
  }, {
    bg_color_hex: '#2a2566',
    id: 630,
    name: 'career',
    text_color_hex: '#ffffff',
  }]);

  it('shows nothing if there is no current user', () => {
    const dataUser = JSON.stringify({
      saw_onboarding: true,
      followed_tag_names: [],
    });
    document.body.setAttribute('data-user', dataUser);
    fetch.mockResponse(fakeResponse);
    const context = shallow(<Onboarding />);
    expect(context.state('showOnboarding')).toEqual(false);
  });

  it('display if  there is current user', () => {
    const dataUser = JSON.stringify({
      followed_tag_names: [{
        bg_color_hex: '#000000',
        id: 715,
        name: 'discuss',
        text_color_hex: '#ffffff',
      }, {
        bg_color_hex: '#f7df1e',
        id: 6,
        name: 'javascript',
        text_color_hex: '#000000',
      }],
    });
    document.body.setAttribute('data-user', dataUser);
    fetch.mockResponse(fakeResponse);
    const context = shallow(<Onboarding />);
    expect(context.state()).toMatchSnapshot();
  });

  it('allows user to interact properly', () => {
    const dataUser = JSON.stringify({
      followed_tag_names: [{
        bg_color_hex: '#000000',
        id: 715,
        name: 'discuss',
        text_color_hex: '#ffffff',
      }, {
        bg_color_hex: '#f7df1e',
        id: 6,
        name: 'javascript',
        text_color_hex: '#000000',
      }, {
        bg_color_hex: '#f7df1e',
        id: 6,
        name: 'javascript',
        text_color_hex: '#000000',
      }],
    });
    document.body.setAttribute('data-user', dataUser);
    const meta = document.createElement('meta');
    meta.setAttribute('name', 'csrf-token');
    document.body.appendChild(meta);
    fetch.mockResponseOnce(fakeResponse);
    const context = deep(<Onboarding />, { depth: 3 });
    context.rerender();
    context.find('.button').simulate('click');
    // going to page two
    expect(context.state('pageNumber')).toEqual(2);
    expect(context.find('[onClick]')).toMatchSnapshot();
    // going to page three
    context.find('.button').at(1).simulate('click');
    expect(context.state('pageNumber')).toEqual(3);
    // going to page four
    context.find('.button').at(1).simulate('click');
    expect(context.state('pageNumber')).toEqual(4);
    fetch.mockResponse(JSON.stringify({ outcome: 'onboarding closed' }));
    // going back to page three
    context.find('.button').at(0).simulate('click');
    expect(context.state('pageNumber')).toEqual(3);
    // going back to page four
    context.find('.button').at(1).simulate('click');
    expect(context.state('pageNumber')).toEqual(4);
    // evaluting the button text on page 4
    expect(context.find('[onClick]').at(2).text()).toEqual("LET'S GO");
    context.find('.button').at(1).simulate('click');
    // clicking the final button
    setImmediate(() => {
      expect(context.state('showOnboarding')).toEqual(false);
    });
  });

  xit('allow user to follow tags flawlessly', async () => {
    const dataUser = JSON.stringify({
      followed_tag_names: [{
        bg_color_hex: '#000000',
        id: 715,
        name: 'discuss',
        text_color_hex: '#ffffff',
      }, {
        bg_color_hex: '#f7df1e',
        id: 6,
        name: 'javascript',
        text_color_hex: '#000000',
      }],
    });
    document.body.setAttribute('data-user', dataUser);
    const meta = document.createElement('meta');
    meta.setAttribute('name', 'csrf-token');
    document.body.appendChild(meta);
    fetch.mockResponseOnce(fakeResponse);
    const context = await deep(<Onboarding />, { depth: 10 });
    context.setState({ pageNumber: 2 });
    context.rerender();
    console.log(context.find('.onboarding-tag-link-follow'));
  });
});
