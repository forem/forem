import { h } from 'preact';
import { shallow } from 'preact-render-spy';
import render from 'preact-render-to-json';
import fetch from 'jest-fetch-mock';
import { SingleRepo } from '../singleRepo';

global.fetch = fetch;

describe('<SingleRepo />', () => {
  describe('when it is not already featured', () => {
    const subject = (
      <SingleRepo
        githubIdCode={123}
        name="dev.to"
        fork={false}
        featured={false}
      />
    );

    it('should render and match the snapshot', () => {
      const tree = render(subject);
      expect(tree).toMatchSnapshot();
    });

    it('should have a state of { featured: false }', () => {
      const context = shallow(subject);
      expect(context.state()).toEqual({ featured: false });
    });
  });

  describe('when it is featured', () => {
    const subject = (
      <SingleRepo githubIdCode={123} name="dev.to" fork={false} featured />
    );
    it('should render and match the snapshot', () => {
      const tree = render(subject);
      expect(tree).toMatchSnapshot();
    });

    it('should have a state of { featured: true }', () => {
      const context = shallow(subject);
      expect(context.state()).toEqual({ featured: true });
    });
  });

  describe('when it is a fork', () => {
    const subject = (
      <SingleRepo githubIdCode={123} name="dev.to" fork featured={false} />
    );

    it('should render and match the snapshot', () => {
      const tree = render(subject);
      expect(tree).toMatchSnapshot();
    });
  });
});
