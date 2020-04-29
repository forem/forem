import { h } from 'preact';
import render from 'preact-render-to-json';
import SelectedTags from '../components/SelectedTags';

const firstTag = {
  id: 1,
  tag: 'clojure',
};
const secondTag = {
  id: 2,
  tag: 'java',
};
const thirdTag = {
  id: 3,
  tag: 'dotnet',
};

const tags = [firstTag, secondTag, thirdTag];
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
