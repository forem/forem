import { h } from 'preact';
import { localeArray , locale } from '../../../utilities/locale';

export const ArticleFormTitle = () => (
  <div
    data-testid="title-help"
    className="crayons-article-form__help crayons-article-form__help--title"
  >
    <h4 className="mb-2 fs-l">{locale('views.editor.help.title.title')}</h4>
    <ul className="list-disc pl-6 color-base-70">
      {localeArray('views.editor.help.title.itens').map((i) => {
        return <li key={i}>{i}</li>;
      })}
    </ul>
  </div>
);
