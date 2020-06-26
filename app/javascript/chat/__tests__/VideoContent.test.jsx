import { h } from 'preact';
import { axe } from 'jest-axe';
import { render } from '@testing-library/preact';
import { VideoContent } from '../videoContent';

describe('<VideoContent />', () => {
  it('should have no a11y violations', async () => {
    const { container } = render(
      <VideoContent
        videoPath="/some-video-path"
        fullscreen="false"
        onTriggerVideoContent={jest.fn()}
      />,
    );
    const results = await axe(container);

    expect(results).toHaveNoViolations();
  });

  it('should render in fullscreen', () => {
    const { queryByLabelText } = render(
      <VideoContent
        videoPath="/some-video-path"
        fullscreen
        onTriggerVideoContent={jest.fn()}
      />,
    );

    expect(queryByLabelText('Leave fullscreen')).toBeNull();
    expect(queryByLabelText('Fullscreen')).toBeDefined();
  });

  it('should not render in fullscreen', () => {
    const { queryByLabelText } = render(
      <VideoContent
        videoPath="/some-video-path"
        fullscreen={false}
        onTriggerVideoContent={jest.fn()}
      />,
    );

    expect(queryByLabelText('Fullscreen')).toBeNull();
    expect(queryByLabelText('Leave fullscreen')).toBeDefined();
  });

  it('should trigger video content when clicked', () => {
    const onTriggerVideoContent = jest.fn();

    const { getByTestId } = render(
      <VideoContent
        videoPath="/some-video-path"
        fullscreen
        onTriggerVideoContent={onTriggerVideoContent}
      />,
    );

    getByTestId('connect-video').click();

    expect(onTriggerVideoContent).toHaveBeenCalledTimes(1);
  });

  it('should load the given video', () => {
    const onTriggerVideoContent = jest.fn();

    const { getByTitle } = render(
      <VideoContent
        videoPath="/some-video-path"
        fullscreen
        onTriggerVideoContent={onTriggerVideoContent}
      />,
    );

    const videoFrame = getByTitle('Video display');

    expect(videoFrame.getAttribute('src')).toEqual('/some-video-path');
  });
});
