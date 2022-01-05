import { h } from 'preact';
import { localeArray , locale } from '../../../utilities/locale';

export const TagInput = () => (
  <div
    data-testid="basic-tag-input-help"
    className="crayons-article-form__help crayons-article-form__help--tags"
  >
    <h4 className="mb-2 fs-l">{locale('views.editor.help.tags.title')}</h4>
    <ul className="list-disc pl-6 color-base-70">
      {localeArray('views.editor.help.tags.itens').map((i) => {
        return <li key={i}>{i}</li>;
      })}
    </ul>
  </div>
);
