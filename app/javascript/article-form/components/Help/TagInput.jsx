import { h } from 'preact';

export const TagInput = () => (
  <div
    data-testid="basic-tag-input-help"
    className="crayons-article-form__help crayons-article-form__help--tags"
  >
    <h4 className="mb-2 fs-l">Шо по теґам?</h4>
    <ul className="list-disc pl-6 color-base-70">
      <li>Теґи допомагають людям знаходити ваш допис.</li>
      <li>
        Теґи - це теми або категорії, які найкраще описують ваш допис.
      </li>
      <li>
		Додавайте до чотирьох тегів, розділених комами, до кожного допису.
		Комбінуйте теги, щоб охопити відповідні підспільноти.
      </li>
      <li>Використовуйте наявні теги, коли це можливо.</li>
      <li>
        Для деяких теґів, наприклад як “моягра“, існують особливі правила публікації.
      </li>
    </ul>
  </div>
);
