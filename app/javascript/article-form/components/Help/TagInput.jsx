import { h } from 'preact';
import { i18next } from '@utilities/locale';

export const TagInput = () => (
  <div
    data-testid="basic-tag-input-help"
    className="crayons-article-form__help crayons-article-form__help--tags"
  >
    <h4 className="mb-2 fs-l">{i18next.t('editor.help.tag.heading')}</h4>
    <ul className="list-disc pl-6 color-base-70">
      <li>{i18next.t('editor.help.tag.desc1')}</li>
      <li>{i18next.t('editor.help.tag.desc2')}</li>
      <li>{i18next.t('editor.help.tag.desc3')}</li>
      <li>{i18next.t('editor.help.tag.desc4')}</li>
      <li>{i18next.t('editor.help.tag.desc5')}</li>
    </ul>
  </div>
);
