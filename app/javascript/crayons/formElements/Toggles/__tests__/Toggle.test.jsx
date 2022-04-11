import { h } from 'preact';
import { render } from '@testing-library/preact';
import { axe } from 'jest-axe';
import { Toggle } from '@crayons';

describe('<Toggle />', () => {
  it('should have no a11y violations when rendered with a label', async () => {
    const { container } = render(
      // Disabling this lint warning, as the linter doesn't know the <Toggle /> component includes the input it's looking for
      // eslint-disable-next-line jsx-a11y/label-has-associated-control
      <label>
        Example label
        <Toggle />
      </label>,
    );
    const results = await axe(container);
    expect(results).toHaveNoViolations();
  });

  it('should render default', () => {
    const { container } = render(<Toggle />);
    expect(container.innerHTML).toMatchSnapshot();
  });

  it('should render with additional input props', () => {
    const { container } = render(
      <Toggle disabled={true} className="example-class" />,
    );
    expect(container.innerHTML).toMatchSnapshot();
  });
});
