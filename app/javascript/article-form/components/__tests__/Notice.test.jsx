import { h } from 'preact';
import render from 'preact-render-to-json';
import Notice from '../notice';

describe('<notice />', () => {
  it('renders properly when published with a first version', () => {
    const tree = render(<Notice published version="v1" />);
    expect(tree).toMatchSnapshot();
  });

  it('renders properly when published with a second version', () => {
    const tree = render(<Notice published version="v2" />);
    expect(tree).toMatchSnapshot();
  });

  it('renders properly when unpublished without a version', () => {
    const tree = render(<Notice version="" />);
    expect(tree).toMatchSnapshot();
  });

  it('renders properly when unpublished with a version', () => {
    const tree = render(<Notice version="v2" />);
    expect(tree).toMatchSnapshot();
  });
});
