import { h } from 'preact';
import render from 'preact-render-to-json';
import CodeEditor from '../codeEditor';

const getCodeEditor = () => (
  <CodeEditor activeChannelId={12345} pusherKey="ASDFGHJKL" />
);

describe('<CodeEditor />', () => {
  it('should render and test snapshot', () => {
    const tree = render(getCodeEditor());
    expect(tree).toMatchSnapshot();
  });
});
