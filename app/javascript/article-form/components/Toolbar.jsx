import { h } from 'preact';
import { ImageUploader } from './ImageUploader';

export const Toolbar = () => {
  return (
    <div className="crayons-article-form__toolbar">
      <ImageUploader />
    </div>
  );
};

Toolbar.displayName = 'Toolbar';
