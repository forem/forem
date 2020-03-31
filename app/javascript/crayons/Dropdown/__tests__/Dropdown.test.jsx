import { h } from 'preact';
import render from 'preact-render-to-json';
import { Dropdown } from '@crayons';

describe('<Dropdown />', () => {
  it('renders properly', () => {
    const tree = render(
      <Dropdown>
        Hey, I&apos;m a dropdown content! Lorem ipsum dolor sit amet,
        consectetur adipisicing elit. Sequi ea voluptates quaerat eos
        consequuntur temporibus.
      </Dropdown>,
    );
    expect(tree).toMatchSnapshot();
  });

  it('renders properly with additional CSS classes', () => {
    const tree = render(
      <Dropdown className="some-additional-css-class">
        Hey, I&apos;m a dropdown content! Lorem ipsum dolor sit amet,
        consectetur adipisicing elit. Sequi ea voluptates quaerat eos
        consequuntur temporibus.
      </Dropdown>,
    );
    expect(tree).toMatchSnapshot();
  });
});
