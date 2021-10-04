import { h } from 'preact';
import { i18next } from '@utilities/locale';

export const ArticleFormTitle = () => (
  <div
    data-testid="title-help"
    className="crayons-article-form__help crayons-article-form__help--title"
  >
    <h4 className="mb-2 fs-l">{i18next.t('editor.help.title.heading')}</h4>
    <ul className="list-disc pl-6 color-base-70">
      <li>{i18next.t('editor.help.title.desc1')}</li>
      <li>{i18next.t('editor.help.title.desc2')}</li>
    </ul>
  </div>
);
