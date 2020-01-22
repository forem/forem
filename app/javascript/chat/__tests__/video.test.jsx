import { h } from 'preact';
import render from 'preact-render-to-json';
import { deep } from 'preact-render-spy';
import fetch from 'jest-fetch-mock';
import Video from '../video';

global.fetch = fetch;

let exited;
exited = false;

const exitVideo = () => {
  exited = true;
};

describe('<Video />', () => {
  it('should render properly and test snapshot', () => {
    const tree = render(<Video activeChannelId={12345} onExit={exitVideo} />);
    expect(tree).toMatchSnapshot();
  });

  it('should have the proper elements, classes and information', () => {
    const context = deep(<Video activeChannelId={12345} onExit={exitVideo} />);

    // check elements
    expect(context.find('.chat__videocall').exists()).toEqual(true);
    expect(context.find('.chat__remotevideoscreen-0').exists()).toEqual(true);
    expect(context.find('.chat__localvideoscren').exists()).toEqual(true);
    const exitButton = context.find('.chat__videocallexitbutton');
    expect(exitButton.exists()).toEqual(true);
    expect(exitButton.text()).toEqual('×');

    // test exit button behaves
    exitButton.simulate('click');
    expect(exited).toEqual(true);
  });
});
