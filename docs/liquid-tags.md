Liquid tags are a special element of the [dev.to](/) markdown editor.

They are custom embeds that are added via `{% %}` syntax. [Liquid](https://shopify.github.io/liquid/) is a templating language developed by Shopify.

Liquid embeds are for tweets, like `{% tweet 765282762081329153 }` or a DEV user profile preview, like `{% user jess %}` etc.

They make for good community contributions because they can be extended and improved on consistently. It is truly how we extend the functionality of the editor. At the moment, there could be a lot of work refactoring and improving existing liquid tags, in addition to adding new ones.

Liquid tags are sort of like functions, which have a name and take arguments. Develop them with that mindset in terms of naming things. They should be documented but also intuitive. They should also be fairly flexible in the arguments they take. Currently this could use improvements.

Liquid tags are "compiled" when an article is saved. So you will need to re-save articles to see HTML changes.
