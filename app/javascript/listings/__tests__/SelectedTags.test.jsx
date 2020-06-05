import { h } from 'preact';
import render from 'preact-render-to-json';
import SelectedTags from '../components/SelectedTags';

const tags = ['clojure', 'java', 'dotnet'];
const getProps = () => ({
  tags,
  onClick: () => {
    return 'onClick';
  },
  onKeyPress: () => {
    return 'onKeyPress';
  },
});

describe('<SelectedTags />', () => {
  const renderSelectedTags = () => render(<SelectedTags {...getProps()} />);

  it('Should render all the tags', () => {
    const context = renderSelectedTags();
    expect(context).toMatchSnapshot();
  });
});
