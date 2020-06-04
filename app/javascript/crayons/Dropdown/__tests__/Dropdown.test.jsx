import { h } from 'preact';
import { render } from '@testing-library/preact';
import { axe } from 'jest-axe';
import { Dropdown } from '@crayons';

describe('<Dropdown />', () => {
  it('should have no a11y violations when rendered', async () => {
    const { container } = render(
      <Dropdown>
        Hey, I&apos;m a dropdown content! Lorem ipsum dolor sit amet,
        consectetur adipisicing elit. Sequi ea voluptates quaerat eos
        consequuntur temporibus.
      </Dropdown>,
    );

    const results = await axe(container);

    expect(results).toHaveNoViolations();
  });

  it('should render', () => {
    const { container } = render(
      <Dropdown>
        Hey, I&apos;m a dropdown content! Lorem ipsum dolor sit amet,
        consectetur adipisicing elit. Sequi ea voluptates quaerat eos
        consequuntur temporibus.
      </Dropdown>,
    );
    expect(container).toMatchSnapshot();
  });

  it('should render with additional CSS classes', () => {
    const { container } = render(
      <Dropdown className="some-additional-css-class">
        Hey, I&apos;m a dropdown content! Lorem ipsum dolor sit amet,
        consectetur adipisicing elit. Sequi ea voluptates quaerat eos
        consequuntur temporibus.
      </Dropdown>,
    );
    expect(container).toMatchSnapshot();
  });
});
