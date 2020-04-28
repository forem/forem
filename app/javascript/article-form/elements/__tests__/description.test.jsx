import { h } from 'preact';
import render from 'preact-render-to-json';
import Description from '../description';

describe('<Description />', () => {
  it('should render the description', () => {
    const context = render(
      <Description
        defaultValue="Some description"
        onChange={() => {
          return 'onChange';
        }}
      />,
    );
    expect(context).toMatchSnapshot();
  });
});
