import { h } from 'preact';
import { shallow } from 'preact-render-spy';
import render from 'preact-render-to-json';
import fetch from 'jest-fetch-mock';
import { SingleRepo } from '../singleRepo';

global.fetch = fetch;

describe('<SingleRepo />', () => {
  describe('when it is not already selected', () => {
    const subject = (
      <SingleRepo
        githubIdCode={123}
        name="dev.to"
        fork={false}
        selected={false}
      />
    );

    it('should render and match the snapshot', () => {
      const tree = render(subject);
      expect(tree).toMatchSnapshot();
    });

    it('should have a state of { selected: false }', () => {
      const context = shallow(subject);
      expect(context.state()).toEqual({ selected: false });
    });
  });

  describe('when it is selected', () => {
    const subject = (
      <SingleRepo githubIdCode={123} name="dev.to" fork={false} selected />
    );
    it('should render and match the snapshot', () => {
      const tree = render(subject);
      expect(tree).toMatchSnapshot();
    });

    it('should have a state of { selected: true }', () => {
      const context = shallow(subject);
      expect(context.state()).toEqual({ selected: true });
    });
  });

  describe('when it is a fork', () => {
    const subject = (
      <SingleRepo githubIdCode={123} name="dev.to" fork selected={false} />
    );

    it('should render and match the snapshot', () => {
      const tree = render(subject);
      expect(tree).toMatchSnapshot();
    });
  });
});
