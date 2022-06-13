import { h } from 'preact';
import { LoadingPreview } from '../LoadingPreview';
import '../../../../assets/stylesheets/preview.scss';

export default {
  title: 'App Components/Preview Loading',
  component: LoadingPreview,
  decorators: [(story) => <div style={{ minWidth: '509px' }}>{story()}</div>],
};

export const DefaultPreview = () => <LoadingPreview />;

DefaultPreview.story = {
  name: 'default',
};

export const CoverLoadingPreview = () => <LoadingPreview version="cover" />;

CoverLoadingPreview.story = {
  name: 'cover',
};
