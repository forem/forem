import { h } from 'preact';
import render from 'preact-render-to-json';
// import { shallow, deep } from 'preact-render-spy';
import CodeEditor from '../codeEditor';
// import CodeMirror from 'codemirror';
// import 'codemirror/mode/javascript/javascript';
// import 'codemirror/mode/jsx/jsx';
// import 'codemirror/mode/ruby/ruby';
// import { JSDOM } from 'jsdom';

const getCodeEditor = () => (
  <CodeEditor activeChannelId={12345} pusherKey="ASDFGHJKL" />
);

describe('<CodeEditor />', () => {
  // beforeEach(() => {
  //   const doc = new JSDOM('<!doctype html><html><body></body></html>');
  //   global.document = doc;
  //   global.window = doc.defaultView;
  //   global.window.initEditorResize = jest.fn();
  //   global.document.body.innerHTML = "<div id='codeeditor' className='chatcodeeditor'></div>";
  // });

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
