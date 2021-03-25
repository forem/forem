---
title: Internationalization (i18n)
---

# Internationalization (i18n)

## What is internationlization (i18n)?

To over simplify the concept a bit, internalization (i18n for short) is the
process of making the platform more user-friendly in various languages for
people around the globe. This includes, but is certainly not limited to, things
like making the site available in different languages, changing currency values
to match your region, changing date formats, etc.

## What do we currently support?

We introduced some routing to lay the groundwork for a more comprehensive i18n
implementation.

## What is the goal?

We want everyone to feel included, regardless of where they're located or what
language(s) they speak. The goal is to make the platform available in various
languages.

## How do you get involved?

The following is a high level outline of an approach to internationalization.
This is by no means set in stone.

We encourage you to open a pull request (PR) to this documentation or to
contribute to internationalization with your ideas - we're
[open-source](https://github.com/forem/forem/pulls)!

## Routing

We have logic for routes setup. You can visit a page and add `/locale/:locale`
to the beginning of the path. For example, if you visit the homepage, you can
add `/locale/fr-ca` for French, Canadian where `fr` is the language code and
`ca` is the region code.

Setting up languages under this "sub-folder" approach helps with Search Engine
Optimization (SEO), routing, and more.

_Currently, the various language routes will not do anything - it will stil show
the site in English (US)._

Once i18n is up and running, users will be able to select their preferred
language to view the platform in. These routes will be the location of various
languages.

## Translating content

There are many ways to translate static content on the platform. To start, we
can explore tools like [i18n-tasks](https://glebm.github.io/i18n-tasks/) which
also has an option to leverage Google Translate programmatically. We'll need to
create locale files (likely `.yml`) to house the translations.

## Search Engine Optimization (SEO)

It seems search engines, especially Google, don't particularly like content on a
page to be in multiple languages. To account for this on pages like articles, we
can try an approach using the canonical URL for the language the article was
written in.

For example, if we detect an article is written in Spanish, we can set the
canonical URL for that article to be `/locale/es/username/article-slug`. We can
then hide comments that are not in the same language as the article/rest of the
page (Spanish in this example) only for the views the crawlers would see. That
way, when the search engine crawler hits an article written in Spanish, the
crawler will see the entire page in Spanish. We will not hide comments for the
views that real users see.

## Caching

The platform relies on edge caching, especially with regards to articles. To
account for this, we'll need to add logic at the edge that understands what
languages the platform currently supports and where to look up the language
variant in the cache.

If the edge doesn't pick up on a user selected preference (possibly sent as an
additional header or cookie), the edge will look at the `Accept-Language` header
and normalize it. The header can include more specific preferences and look
something like: `Accept-Language: fr-ca, fr;q=0.9, en;q=0.8, de;q=0.7, *;q=0.5`.
There are 2 things going on here. 1) A user can specify country/region variants
for a language - `fr-ca` (French - Canada) and `fr-fr` (French - France). For
simplicity's sake, we want to normalize that sort of preference to `fr` to
start. 2) A user can specify priority using the q argument. We'll want to
interpret the user's priority preferences to match their highest priority
language with one we currently support.

Once the edge is aware of what language it should be looking for, it will set
the cache key accordingly.

We also make use of fragment caching in several places. We need to update the
keys for those caches to account for `locale` so we're not mistakenly serving a
cached fragment in a different language than intended.

## Additional considerations

- _Translating URLs_. For the best SEO result, we should also translate URLs
  themselves into various languages. Something like the `/about` page could be
  translated, for example. For now, we aren't going to account for this.
- _Translating dynamic/user generated content_. For now, we plan to _not_
  automatically translate any dynamic/user generated content (articles,
  comments, listings, etc.). In the future we could explore what that looks
  like, how a user can opt-in/out of that, etc.

## Styles, design, and UI

We'll want to expand some design aspects to support other languages that may be
right-to-left, have different spacings, have special characters, etc.

## Next steps

A few next steps we can take on the road to internationalization.

- Update our logic to allow special characters/encodings in URLs. Currently, we
  generate slugs on dynamic content like articles and tags that may include
  characters that make the URL
  invalid.[Here](https://github.com/forem/forem/issues/10116) is a good example.
  We want to update this logic so these characters work in URLs as expected.
- Allow Forem Admins to set a "default language". Currently, if a user doesn't
  select a language preference, it defaults to English ("en").
- Clean up some code. There are some places we're hard-coding strings on the
  frontend. We'll want to explore moving that sort data to the backend to unify
  where and how we're translating.
- Translate areas of the site into English (US) first to ensure things are still
  working. In other words, have the platform adhere to the default locale
  instead of hard-coded strings.
- Start translating!

## Resources

- [Rails Guides - Rails Internationalization (I18n)](https://guides.rubyonrails.org/i18n.html)
- [i18n-tasks](https://glebm.github.io/i18n-tasks/)
- [Google: Managing multi-regional and multilingual sites](https://support.google.com/webmasters/answer/182192)
- [forem.dev post: What internationalization features should we support?](https://forem.dev/vaidehijoshi/what-internationalization-features-should-we-support-4kl)
