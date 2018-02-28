import { h } from 'preact';
import { render } from 'preact-render-to-json';
import OnboardingWelcome from '../OnboardingWelcome';

describe('<OnboardingWelcome />', () => {
  it('renders correctly', () => {
    const tree = render(<OnboardingWelcome />);
    expect(tree).toMatchSnapshot();
  });
});
