import { h } from 'preact';
import { shallow, deep } from 'preact-render-spy';
import fetch from 'jest-fetch-mock';
import Onboarding from '../Onboarding';

global.fetch = fetch;

function flushPromises() {
  return new Promise(resolve => setImmediate(resolve));
}

describe('<Onboarding />', () => {
  afterEach(() => {
    document.body.setAttribute('data-user', null);
  });

  const fakeResponse = JSON.stringify([
    {
      bg_color_hex: '#000000',
      id: 715,
      name: 'discuss',
      text_color_hex: '#ffffff',
    },
    {
      bg_color_hex: '#f7df1e',
      id: 6,
      name: 'javascript',
      text_color_hex: '#000000',
    },
    {
      bg_color_hex: '#2a2566',
      id: 630,
      name: 'career',
      text_color_hex: '#ffffff',
    },
  ]);

  const dataUser = JSON.stringify({
    followed_tag_names: [
      {
        bg_color_hex: '#000000',
        id: 715,
        name: 'discuss',
        text_color_hex: '#ffffff',
      },
      {
        bg_color_hex: '#f7df1e',
        id: 6,
        name: 'javascript',
        text_color_hex: '#000000',
      },
    ],
  });

  const usersState = [
    {
      id: 1,
      name: 'Ben Halpern',
      profile_image_url: 'ben.jpg',
    },
    {
      id: 2,
      name: 'Krusty the Clown',
      profile_image_url: 'clown.jpg',
    },
    {
      id: 3,
      name: 'dev.to staff',
      profile_image_url: 'dev.jpg',
    },
  ];

  describe('when user is not logged in', () => {
    beforeEach(() => {
      fetch.mockResponse(fakeResponse);
      document.body.setAttribute(
        'data-user',
        JSON.stringify({ saw_onboarding: true }),
      );
    });

    test('showOnboarding is false', () => {
      const context = shallow(<Onboarding />);
      expect(context.state('showOnboarding')).toEqual(false);
    });

    test('nothing should be rendered', async () => {
      // TODO: dataUser should be {};
      const context = shallow(<Onboarding />);
      await flushPromises();
      expect(context).toMatchSnapshot();
    });
  });

  describe('Welcome page', () => {
    let context;
    beforeEach(async () => {
      fetch.mockResponse(fakeResponse);
      document.body.setAttribute('data-user', dataUser);
      context = deep(<Onboarding />);
      await flushPromises();
    });

    test('renders properly', () => {
      expect(context).toMatchSnapshot();
    });

    test('NEXT button should work', () => {
      context.find('.button').simulate('click');
      expect(context.state('pageNumber')).toEqual(2);
      expect(context).toMatchSnapshot();
    });

    // TODO: test closing button
  });

  describe('Follow tag page', () => {
    let context;
    beforeEach(async () => {
      fetch.mockResponseOnce(fakeResponse);
      document.body.setAttribute('data-user', dataUser);
      context = deep(<Onboarding />);
      context.setState({ pageNumber: 2 });
      await flushPromises();
    });

    test('renders properly', () => {
      expect(context).toMatchSnapshot();
    });

    test('BACK button works', () => {
      context
        .find('.button')
        .at(0)
        .simulate('click');
      expect(context.state('pageNumber')).toEqual(1);
      expect(context).toMatchSnapshot();
    });

    test('NEXT button works', async () => {
      fetch.mockResponseOnce(JSON.stringify(usersState));
      context
        .find('.button')
        .at(1)
        .simulate('click');
      await flushPromises();
      expect(context.state('pageNumber')).toEqual(3);
      expect(context).toMatchSnapshot();
    });
  });

  describe('Follow dev members page', () => {
    let context;
    beforeEach(async () => {
      fetch.mockResponse(fakeResponse);
      document.body.setAttribute('data-user', dataUser);
      context = shallow(<Onboarding />);
      context.setState({ pageNumber: 3, usersState });
      await flushPromises();
    });

    test('renders properly', () => {
      expect(context).toMatchSnapshot();
    });

    test('BACK button works', () => {
      context
        .find('.button')
        .at(0)
        .simulate('click');
      expect(context.state('pageNumber')).toEqual(2);
      expect(context).toMatchSnapshot();
    });

    test('NEXT button works', () => {
      context
        .find('.button')
        .at(1)
        .simulate('click');
      expect(context.state('pageNumber')).toEqual(4);
      expect(context).toMatchSnapshot();
    });
  });

  xit('display if there is current user', async () => {
    document.body.setAttribute('data-user', dataUser);
    fetch.mockResponse(fakeResponse);
    const context = shallow(<Onboarding />);
    await flushPromises();
    expect(context).toMatchSnapshot();
  });

  xit('allows user to interact properly', async () => {
    document.body.setAttribute('data-user', dataUser);
    const meta = document.createElement('meta');
    meta.setAttribute('name', 'csrf-token');
    document.body.appendChild(meta);
    fetch.mockResponseOnce(fakeResponse);

    const context = deep(<Onboarding />, { depth: 3 });
    // context.setState({ users: usersState });
    // context.rerender();
    await flushPromises();
    context.find('.button').simulate('click');

    // going to page two
    expect(context.state('pageNumber')).toEqual(2);
    expect(context.find('[onClick]')).toMatchSnapshot();

    // going to page three
    context
      .find('.button')
      .at(1)
      .simulate('click');
    console.log(context.state());
    expect(context.state('pageNumber')).toEqual(3);
    // going to page four
    context
      .find('.button')
      .at(1)
      .simulate('click');
    expect(context.state('pageNumber')).toEqual(4);
    // going to page five
    context
      .find('.button')
      .at(1)
      .simulate('click');
    expect(context.state('pageNumber')).toEqual(5);
    fetch.mockResponse(JSON.stringify({ outcome: 'onboarding closed' }));
    // going back to page four
    context
      .find('.button')
      .at(0)
      .simulate('click');
    expect(context.state('pageNumber')).toEqual(4);
    // going back to page five
    context
      .find('.button')
      .at(1)
      .simulate('click');
    expect(context.state('pageNumber')).toEqual(5);
    // evaluting the button text on page five
    expect(
      context
        .find('[onClick]')
        .at(2)
        .text(),
    ).toEqual("LET'S GO");
    context
      .find('.button')
      .at(1)
      .simulate('click');
    // clicking the final button
    await flushPromises();
    expect(context.state('showOnboarding')).toEqual(false);
  });

  xit('allow user to follow tags flawlessly', async () => {
    const dataUser = JSON.stringify({
      followed_tag_names: [
        {
          bg_color_hex: '#000000',
          id: 715,
          name: 'discuss',
          text_color_hex: '#ffffff',
        },
        {
          bg_color_hex: '#f7df1e',
          id: 6,
          name: 'javascript',
          text_color_hex: '#000000',
        },
      ],
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
