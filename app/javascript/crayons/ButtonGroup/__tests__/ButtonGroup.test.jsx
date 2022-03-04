import { h } from 'preact';
import { render } from '@testing-library/preact';
import { axe } from 'jest-axe';
import { Button, ButtonGroup } from '@crayons';

describe('<ButtonGroup /> component', () => {
  const Icon = () => (
    <svg
      width="24"
      height="24"
      xmlns="http://www.w3.org/2000/svg"
      className="crayons-icon"
    >
      <path d="M9.99999 15.172L19.192 5.979L20.607 7.393L9.99999 18L3.63599 11.636L5.04999 10.222L9.99999 15.172Z" />
    </svg>
  );

  it('should have no a11y violations when rendered', async () => {
    const { container } = render(
      <ButtonGroup labelText="Test button group">
        <Button>Hello World!</Button>
        <Button variant="secondary">Hello again!</Button>
      </ButtonGroup>,
    );
    const results = await axe(container);

    expect(results).toHaveNoViolations();
  });

  it('should render', () => {
    const { container } = render(
      <ButtonGroup labelText="Test button group">
        <Button>Hello World!</Button>
        <Button icon={Icon} />
      </ButtonGroup>,
    );
    expect(container.innerHTML).toMatchSnapshot();
  });
});
