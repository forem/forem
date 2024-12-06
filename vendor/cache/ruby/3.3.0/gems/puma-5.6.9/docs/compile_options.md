# Compile Options

There are some `cflags` provided to change Puma's default configuration for its
C extension.

## Query String, `PUMA_QUERY_STRING_MAX_LENGTH`

By default, the max length of `QUERY_STRING` is `1024 * 10`. But you may want to
adjust it to accept longer queries in GET requests.

For manual install, pass the `PUMA_QUERY_STRING_MAX_LENGTH` option like this:

```
gem install puma -- --with-cflags="-D PUMA_QUERY_STRING_MAX_LENGTH=64000"
```

For Bundler, use its configuration system:

```
bundle config build.puma "--with-cflags='-D PUMA_QUERY_STRING_MAX_LENGTH=64000'"
```
