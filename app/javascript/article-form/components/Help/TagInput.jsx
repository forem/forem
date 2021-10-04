import { h } from 'preact';
import { i18next } from '../../../i18n/l10n';

export const TagInput = () => (
  <div
    data-testid="basic-tag-input-help"
    className="crayons-article-form__help crayons-article-form__help--tags"
  >
    <h4 className="mb-2 fs-l">{i18next.t('editor.help.tag.heading')}</h4>
    <ul className="list-disc pl-6 color-base-70">
      <li>{i18next.t('editor.help.tag.desc_1')}</li>
      <li>{i18next.t('editor.help.tag.desc_2')}</li>
      <li>{i18next.t('editor.help.tag.desc_3')}</li>
      <li>{i18next.t('editor.help.tag.desc_4')}</li>
      <li>{i18next.t('editor.help.tag.desc_5')}</li>
    </ul>
  </div>
);
