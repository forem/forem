import { h } from 'preact';

export const ArticleFormTitle = () => (
  <div
    data-testid="title-help"
    className="crayons-article-form__help crayons-article-form__help--title"
  >
    <h4 className="mb-2 fs-l">Написання крутого заголовку</h4>
    <ul className="list-disc pl-6 color-base-70">
      <li>
		Подумайте про назву вашого допису як про дуже короткий (але переконливий!)
		опис - як огляд самої публікації в одному короткому реченні.
      </li>
      <li>
        Використовуйте ключові слова там, де це доречно, щоб люди могли знайти
		вашу публікацію за допомогою пошуку.
      </li>
    </ul>
  </div>
);
