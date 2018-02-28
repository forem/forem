import { h } from 'preact';
import { render } from 'preact-render-to-json';
import OnboardingWelcomeThread from '../OnboardingWelcomeThread';

describe('<OnboardingWelcomeThread />', () => {
  it('renders correctly', () => {
    const tree = render(<OnboardingWelcomeThread />);
    expect(tree).toMatchSnapshot();
  });
});
