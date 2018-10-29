import { h } from 'preact';
import render from 'preact-render-to-json';
// import { shallow } from 'preact-render-spy';
import CodeEditor from '../codeEditor';

const getCodeEditor = () => (
  <CodeEditor activeChannelId={12345} pusherKey="ASDFGHJKL" />
);

describe('<CodeEditor />', () => {
  it('should render and test snapshot', () => {
    const tree = render(getCodeEditor());
    expect(tree).toMatchSnapshot();
  });

  // it('should have the proper attributes and text values', () => {
  //   const context = shallow(getCodeEditor());
  //   expect(context.find('codeeditor').exists()).toEqual(true);
  //   expect(context.find('.chatcodeeditor__header').exists()).toEqual(true);
  //   expect(context.find('.chatcodeeditor__header').text()).toEqual('Experimental (WIP)');
  // });
});
