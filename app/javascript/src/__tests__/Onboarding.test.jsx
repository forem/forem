import { h } from 'preact';
import { shallow, deep } from 'preact-render-spy';
import fetch from 'jest-fetch-mock';
import Onboarding from '../Onboarding';

global.fetch = fetch;

function flushPromises() {
  return new Promise(resolve => setImmediate(resolve));
}

describe('<Onboarding />', () => {
  beforeEach(() => {
    document.body.setAttribute('data-user', null);
    fetch.resetMocks();
  });

  const fakeTagResponse = JSON.stringify([
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
    followed_tag_names: ['javascript'],
  });

  const fakeUsersToFollowResponse = JSON.stringify([
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
  ]);

  describe('when user is not logged in', () => {
    beforeEach(() => {
      fetch.once(fakeTagResponse);
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
      fetch.once(fakeTagResponse);
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
    const meta = document.createElement('meta');
    meta.setAttribute('name', 'csrf-token');
    document.body.appendChild(meta);

    beforeEach(async () => {
      fetch.once(fakeTagResponse);
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
      fetch.once(fakeUsersToFollowResponse);
      context
        .find('.button')
        .at(1)
        .simulate('click');
      await flushPromises();
      expect(context.state('pageNumber')).toEqual(3);
      expect(context).toMatchSnapshot();
    });

    test('each tag can be clicked', async () => {
      fetch.mockResponse(JSON.stringify({ outcome: 'followed' }));
      context.find('.onboarding-tag-link').map(tag => tag.simulate('click'));
      await flushPromises();
      expect(context.state('allTags').map(tag => tag.following)).toEqual([
        true,
        true,
        true,
      ]);
    });

    test('each tag can be clicked (in weird combinations)', async () => {
      fetch.mockResponse(JSON.stringify({ outcome: 'followed' }));
      context
        .find('.onboarding-tag-link')
        .at(1)
        .simulate('click');
      await flushPromises();
      expect(context.state('allTags').map(tag => tag.following)).toEqual([
        false,
        true,
        false,
      ]);
    });
  });

  describe('Follow dev members page', () => {
    let context;
    beforeEach(async () => {
      fetch.once(fakeTagResponse);
      document.body.setAttribute('data-user', dataUser);
      context = deep(<Onboarding />);
      fetch.once(fakeUsersToFollowResponse);
      context.setState({ pageNumber: 2 });
      context
        .find('.button')
        .at(1)
        .simulate('click');
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

    test('NEXT button works', async () => {
      fetch.once(JSON.stringify({}));
      context
        .find('.button')
        .at(1)
        .simulate('click');
      await flushPromises();
      expect(context.state('pageNumber')).toEqual(4);
      expect(context).toMatchSnapshot();
    });
  });

  describe('User info page', () => {
    let context;
    beforeEach(async () => {
      fetch.once(fakeTagResponse);
      document.body.setAttribute('data-user', dataUser);
      context = deep(<Onboarding />);
      context.setState({ pageNumber: 4 });
      await flushPromises();
    });

    test('renders properly', () => {
      expect(context).toMatchSnapshot();
    });

    test('NEXT button works', async () => {
      fetch.once({});
      context
        .find('.button')
        .at(1)
        .simulate('click');
      await flushPromises();
      expect(context.state('pageNumber')).toEqual(5);
    });

    test('BACK button works', () => {
      context
        .find('.button')
        .at(0)
        .simulate('click');
      expect(context.state('pageNumber')).toEqual(3);
    });

    test('forms can be filled and submitted', async () => {
      fetch.once({});
      const targets = [
        'summary',
        'location',
        'employment_title',
        'employer_name',
        'mostly_work_with',
        'currently_learning',
      ];
      const findAndUpdate = target => {
        // TODO: we shouldn't have to add name. This might have to do with preact-render-spy
        const event = { target: { value: 'TEST', name: target } };
        context.find(<input name={target} />).simulate('change', event);
      };

      targets.forEach(findAndUpdate);
      context
        .find('.button')
        .at(1)
        .simulate('click');
      await flushPromises();
      expect(context.state('pageNumber')).toEqual(5);
      const idealResult = {};
      targets.forEach(attr => {
        idealResult[attr] = 'TEST';
      });
      expect(context.state('profileInfo')).toEqual(idealResult);
    });
  });

  describe('Final page', () => {
    let context;
    beforeEach(async () => {
      fetch.once(fakeTagResponse);
      document.body.setAttribute('data-user', dataUser);
      const meta = document.createElement('meta');
      meta.setAttribute('name', 'csrf-token');
      document.body.appendChild(meta);
      context = deep(<Onboarding />);
      context.setState({ pageNumber: 5, profileInfo: { summary: 'hi there' } });
      await flushPromises();
    });

    it('renders properly', () => {
      expect(context).toMatchSnapshot();
    });

    it('special next button exists and should reroute user', async () => {
      fetch.once(JSON.stringify({ outcome: 'onboarding closed' }));
      const next = context.find('.button').at(1);
      expect(next.text()).toEqual("LET'S GO");
      next.simulate('click');
      await flushPromises();
      expect(context.state('pageNumber')).toEqual(5);
      expect(context).toMatchSnapshot();
    });

    it('sends proper update on close', async () => {
      fetch.once(JSON.stringify({ outcome: 'onboarding closed' }));
      context
        .find('.button')
        .at(1)
        .simulate('click');
      await flushPromises();
      expect(context.state('showOnboarding')).toEqual(false);
    });

    it('BACK button works', () => {
      context
        .find('.button')
        .at(0)
        .simulate('click');
      expect(context.state('pageNumber')).toEqual(4);
      expect(context).toMatchSnapshot();
    });
  });
});
