import { h } from 'preact';
import { render } from '@testing-library/preact';
import { axe } from 'jest-axe';
import { Content } from '../content';

const getChannelRequestData = () => ({
  onTriggerContent: jest.fn(),
  type_of: 'channel-request',
  activeChannelId: 12345,
  pusherKey: 'ASDFGHJKL',
  githubToken: '',
  data: {
    channel: {
      name: 'bobby',
    },
    user: {
      username: 'spongebob',
    },
  },
});

const getLoadingUserData = () => ({
  onTriggerContent: jest.fn(),
  type_of: 'loading-user',
  activeChannelId: 1235,
  pusherKey: 'ASDFGHJKL',
  githubToken: '',
  data: {
    user: {
      username: 'spongebob',
    },
  },
});

describe('<Content />', () => {
  describe('as loading-user', () => {
    it('should have no a11y violations', async () => {
      // TODO: The axe custom rules here should be removed when the below issue is fixed
      // https://github.com/forem/forem/issues/14101
      const customAxeRules = {
        'nested-interactive': { enabled: false },
      };

      const channelRequestResource = getChannelRequestData();
      const { container } = render(
        <Content resource={channelRequestResource} />,
      );
      const results = await axe(container, { rules: customAxeRules });

      expect(results).toHaveNoViolations();
    });

    it('should render', () => {
      const channelRequestResource = getChannelRequestData();
      const { queryByText, queryByTitle } = render(
        <Content resource={channelRequestResource} />,
      );

      // Ensure the two buttons render
      expect(queryByTitle('exit')).toBeDefined();
      expect(queryByTitle('fullscreen')).toBeDefined();

      // Simple check if the component to request joining a channel appears.
      // The component itself is tested it in it's own test suite.
      expect(
        queryByText(
          'You are not a member of this group yet. Send a request to join.',
        ),
      ).toBeDefined();
    });
  });

  describe('as channel-request', () => {
    it('should have no a11y violations', async () => {
      // TODO: The axe custom rules here should be removed when the below issue is fixed
      // https://github.com/forem/forem/issues/14101
      const customAxeRules = {
        'nested-interactive': { enabled: false },
      };

      const loadinUserResource = getLoadingUserData();
      const { container } = render(<Content resource={loadinUserResource} />);
      const results = await axe(container, { rules: customAxeRules });

      expect(results).toHaveNoViolations();
    });

    it('should render', () => {
      const loadinUserResource = getLoadingUserData();
      const { queryByTitle } = render(
        <Content resource={loadinUserResource} />,
      );

      // Ensure the two buttons render
      expect(queryByTitle('exit')).toBeDefined();
      expect(queryByTitle('fullscreen')).toBeDefined();
      expect(queryByTitle('Loading user')).toBeDefined();
    });
  });
  /*
  testing only as loading user since components that Content uses
  are independently tested
  */
});
