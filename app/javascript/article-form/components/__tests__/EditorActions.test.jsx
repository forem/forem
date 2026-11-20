import { h } from 'preact';
import { render } from '@testing-library/preact';
import '@testing-library/jest-dom';
import { EditorActions } from '../EditorActions';

describe('<EditorActions />', () => {
  beforeEach(() => {
    window.I18n = {
      t: jest.fn((key) => key),
    };
  });

  it('renders the scheduled footer pill with a formatted title for a future schedule date', () => {
    const futureYear = new Date().getFullYear() + 2;
    const publishedAtDate = `${futureYear}-11-03`;
    const publishedAtTime = '14:30';

    const { getByRole } = render(
      <EditorActions
        onSaveDraft={jest.fn()}
        onPublish={jest.fn()}
        onClearChanges={jest.fn()}
        published={false}
        publishedAtDate={publishedAtDate}
        publishedAtTime={publishedAtTime}
        schedulingEnabled
        edited={false}
        version="v2"
        passedData={{
          publishedAtDate,
          publishedAtTime,
          canonicalUrl: '',
          series: '',
        }}
        onConfigChange={jest.fn()}
        submitting={false}
        previewLoading={false}
        switchHelpContext={jest.fn()}
      />,
    );

    const scheduledPill = getByRole('button', { name: /Scheduled/i, hidden: true });
    expect(scheduledPill).toHaveAttribute(
      'title',
      `November 3, ${futureYear} at 2:30 PM`,
    );
  });
});
