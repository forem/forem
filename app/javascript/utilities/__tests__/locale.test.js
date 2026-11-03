import { locale } from '@utilities/locale';

describe('locale utility', () => {
  beforeEach(() => {
    document.body.innerHTML = `<div id="i18n-translations"></div>`;
    delete document.body.dataset.locale;
    document.getElementById('i18n-translations').dataset.translations =
      JSON.stringify({
        en: {
          core: {
            follow: 'Follow',
            greeting: 'Hello %{name}!',
            counted_users: {
              zero: '0 users',
              one: '1 user',
              other: '%{count} users',
            },
          },
        },
        fr: {
          core: {
            follow: 'Suivre',
          },
        },
      });
  });

  it('resolves nested translation keys in the default locale', () => {
    expect(locale('core.follow')).toEqual('Follow');
  });

  it('interpolates named parameters', () => {
    expect(locale('core.greeting', { name: 'Benoit' })).toEqual(
      'Hello Benoit!',
    );
  });

  it('handles pluralization forms for zero, one, and other', () => {
    expect(locale('core.counted_users', { count: 0 })).toEqual('0 users');
    expect(locale('core.counted_users', { count: 1 })).toEqual('1 user');
    expect(locale('core.counted_users', { count: 4 })).toEqual('4 users');
  });

  it('uses document.body.dataset.locale and falls back to en', () => {
    document.body.dataset.locale = 'fr';
    expect(locale('core.follow')).toEqual('Suivre');
    expect(locale('core.greeting', { name: 'Alex' })).toEqual('Hello Alex!');
  });

  it('synchronizes active locale with #i18n-translations data-locale across page swaps', () => {
    document.body.dataset.locale = 'en';
    const translationsEl = document.getElementById('i18n-translations');
    translationsEl.dataset.locale = 'fr';
    translationsEl.dataset.translations = JSON.stringify({
      fr: {
        core: {
          follow: 'Suivre maintenant',
        },
      },
    });

    expect(locale('core.follow')).toEqual('Suivre maintenant');
  });

  it('returns the standard missing translation notice for unknown keys', () => {
    expect(locale('core.nonexistent_key')).toEqual(
      '[missing "en.core.nonexistent_key" translation]',
    );
  });
});
