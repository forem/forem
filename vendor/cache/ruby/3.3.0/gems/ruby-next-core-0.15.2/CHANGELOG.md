# Change log

## master

## 0.15.2 (2022-08-02)

- Fix loading transpiled in TruffleRuby. ([@palkan][])

TruffleRuby doesn't support all Ruby 3.0 features yet, so we should treat as an older Ruby.

- Use `ruby2_keywords` when transpiling arguments forwarding. ([@palkan][])

That makes transpiled code forward compatible with the modern Ruby versions.

## 0.15.1 (2022-04-05)

- Fix transpiling `rescue` within nested blocks. ([@palkan][])

## 0.15.0 (2022-03-21)

- Support IRB ([@palkan][])

- Create empty `.rbnext` folder during `nextify` if nothing to transpile. ([@palkan][])

This would prevent from auto-transpiling a library every time when no files should be transpiled.

- Auto-transpile using the current Ruby version. ([@palkan][])

- Support Pry. ([@baygeldin][])

- Add `rescue/ensure/else` within block rewriter for Ruby < 2.5. ([@fargelus][])

## 0.14.1 (2022-01-21)

- Fix nested find patterns transpiling. ([@palkan][])

## 0.14.0 🎄

- Add `Integer.try_convert`. ([@palkan][])

- Add `Enumerable#compact`, `Enumerator::Lazy#compact`. ([@palkan][])

- [Proposed] Add support for binding instance, class, global variables in pattern matching. ([@palkan][])

This brings back rightward assignment: `42 => @v`.

- Add `MatchData#match`. ([@palkan][])

- Add support for command syntax in endless methods (`def foo() = puts "bar"`)

- Add `Refinement#import_methods` support. ([@palkan][])

This API only works in conjunction with transpiling, since it couldn't be backported purely as a method and requires passing an additional argument (Binding).

You can find the details in [the PR](https://github.com/ruby-next/ruby-next/pull/85).

- Added support for instance, class and global variables and expressions for pin operator. ([@palkan][])

- Support omitting parentheses in one-line pattern matching. ([@palkan][])

- Anonymous blocks `def b(&); c(&); end` ([@palkan][]).

## 0.13.3 (2021-12-08)

- Revert 0.13.2 and freeze Parser version. ([@skryukov][])

Postpone upgrade 'till v0.14 due to breaking shorthand hash changes.

## 0.13.2 (2021-11-28)

- Parser upgrade.

## 0.13.1 (2021-09-27)

- Fix checking for realpath during $LOAD_PATH setup. ([@palkan][])

## 0.13.0 (2021-09-27)

- Added `Enumerable#tally` with the resulting hash. ([@skryukov][])

- Added `Array#intersect?`. ([@skryukov][])

## 0.12.0 (2021-01-12)

- Added required keyword arguments rewriter. ([@palkan][])

Required kwargs were introduced in 2.1. Now we make them possible in 2.0.

- Added numeric literals rewriter. ([@palkan][])

Now it's possible to generate Ruby 2.0 compatible code from `2i + 1/3r`.

- Fixed several safe navigation (`&.`) bugs. ([@palkan][])

See [#68](https://github.com/ruby-next/ruby-next/issues/68) and [#69](https://github.com/ruby-next/ruby-next/issues/69).

## 0.11.1 (2020-12-28)

- Use separate _namespace_ for proposed features to avoid conflicts with new Ruby version. ([@palkan][])

Previously, we used the upcoming Ruby version number for proposed features (e.g., `3.0.0`), which broke
the load path setup, since transpiled files were not loaded anymore.
Now that's fixed by using a _virtual_ version number for proposals (`1995.next.0`).

## 0.11.0 (2020-12-24) 🎄

- Extended proposed shorthand Hash syntax to support kwargs as well. ([@palkan][])

You can try it: `x = 1; y = 2; foo(x:, y:) # => foo(x: x, y: y)`.

- **Rewrite mode is used by default in transpiler**. ([@palkan][])

- Move 3.0 features to stable features. ([@palkan][])

- Refactor `a => x` and `a in x` to comply with Ruby 3.0. ([@palkan][])

## 0.10.5 (2020-10-13)

- Fix Unparser 0.5.0 compatibility. ([@palkan][])

## 0.10.4 (2020-10-09)

- Restrict Unparser dependency. ([@palkan][])

Unparser 0.5.0 is currently not supported.

## 0.10.3 (2020-09-28)

- Update RuboCop integration to handle the latest Parser changes. ([@palkan][])

Parser 2.7.1.5 unified endless and normal methods and rightward and leftward assignments, thus, making some cops report false negatives.

## 0.10.2 (2020-09-09)

- Fix regression when `nextify` produces incorrect files for 2.7. ([@palkan][])

## ~~0.10.1~~

## 0.10.0 (2020-09-02)

- Add proposed shorthand Hash syntax. ([@palkan][])

You can try it: `x = 1; y = 2; data = {x, y}`.

- Add leading argument support to args forwarding. ([@palkan][])

`def a(...) b(1, ...); end`.

- Add `Hash#except`. ([@palkan][])

`{a: 1, b: 2}.except(:a) == {b: 2}`

- Add find pattern support. ([@palkan][])

Now you can do: `[0, 1, 2] in [*, 1 => a, *c]`.

- Add Ruby 2.2 support. ([@palkan][])

With support for safe navigation operator (`&.`) and squiggly heredocs (`<<~TXT`).

## 0.9.2 (2020-06-24)

- Support passing rewriters to CLI. ([@sl4vr][])

Use `nextify --list-rewriters` to view all available rewriters.
Use `nextify` with `--rewrite=REWRITERS...` option to specify which particular rewriters to use.

## 0.9.1 (2020-06-05)

- Keep `ruby-next` version in sync with `ruby-next-core`. ([@palkan][])

Require `ruby-next-core` of the same version as `ruby-next`.

## 0.9.0 (2020-06-04)

- Add Ruby 2.3 support. ([@palkan][])

- Remove stale transpiled files when running `ruby-next nextify`. ([@palkan][])

- Add Ruby 2.4 support. ([@palkan][])

APIs for <2.5 must be backported via [backports][] gem. Refinements are not supported.

## 0.8.0 (2020-05-01) 🚩

- Add right-hand assignment support. ([@palkan][])

It is real: `13.divmod(5) => a, b`.

- Add endless methods support. ([@palkan][])

Now you can write `def foo() = :bar`.

## 0.7.0 (2020-04-29)

- Try to auto-transpile the source code on load in `.setup_gem_load_path` if transpiled files are missing. ([@palkan][])

This would make it possible to install gems from source if transpiled files do not exist in the repository.

- Use`./.rbnextrc` to define CLI args. ([@palkan][])

You can define CLI options in the configuration file to re-use them between environments or
simply avoid typing every time:

```yml
# .rbnextrc
nextify: |
  --transpiler-mode=rewrite
  --edge
```

- Add `--dry-run` option to CLI. ([@palkan][])

- Raise `SyntaxError` when parsing fails. ([@palkan][])

Previously, we let Parser to raise its `Parser::SyntaxError` but some exceptions
are not reported by Parser and should be handled by transpiler (and we raised `SyntaxError` in that case, as MRI does).

This change unifies the exceptions raised during transpiling.

## 0.6.0 (2020-04-23)

- Changed the way edge/proposed features are activated. ([@palkan][])

Use `--edge` or `--proposed` flags for `ruby-next nextify` or
`require "ruby-next/language/{edge,proposed}"` in your code.

See more in the [Readme](./README.md#proposed-and-edge-features).

- Updated RuboCop integration. ([@palkan][])

Make sure you use `TargetRubyVersion: next` in your RuboCop configuration.

- Upgraded to `ruby-next-parser` for edge features. ([@palkan][])

It's no longer needed to use Parser gem from Ruby Next package registry.

## 0.5.3 (2020-03-25)

- Enhance logging. ([@palkan][])

Use `RUBY_NEXT_WARN=false` to disable warnings.
Use `RUBY_NEXT_DEBUG=path.rb` to display the transpiler output only for matching files
in the runtime mode.

## 0.5.1 (2020-03-20)

- Add RuboCop integration. ([@palkan][])

Adds support for missing node types and fixes some bugs with 2.7.

## 0.5.0 (2020-03-20)

- Add `rewrite` transpiler mode. ([@palkan][])

Add support for rewriting the source code instead of rebuilding it from scratch to
preserve the original layout and improve the debugging experience.

## 0.4.0 (2020-03-09)

- Optimize pattern matching transpiled code. ([@palkan][])

For array patterns, transpiled code is ~1.5-2x faster than native.
For hash patterns it's about the same.

- Pattern matching is 100% compatible with RubySpec. ([@palkan][])

- Add `Symbol#start_with?/end_with?`. ([@palkan][])

## 0.3.0 (2020-02-14) 💕

- Add `Time#floor` and `Time#ceil`. ([@palkan][])

- Add `UnboundMethod#bind_call`. ([@palkan][])

- Add `String#split` with block. ([@palkan][])

- **Check for _native_ method implementation to activate a refinement.** ([@palkan][])

Add a method refinement to `using RubyNext` even if the backport is present. That
helps to avoid the conflicts with invalid monkey-patches.

- Add `ruby-next core_ext` command. ([@palkan][])

This command allows generating custom core extension files. Meant to be used in
alternative Ruby implementations (mruby, Opal, etc.) not compatible with the `ruby-next-core` gem.

- Add `ruby-next/core_ext`. ([@palkan][])

Now you can use core extensions (monkey-patches) instead of the refinements.

- Check whether pattern matching target respond to `#deconstruct` / `#deconstruct_keys`. ([@palkan][])

- Fix `Struct#deconstruct_keys` to respect passed keys. ([@palkan][])

## 0.2.0 (2020-01-13) 🎄

- Add `Enumerator.produce`. ([@palkan][])

- Add Bootsnap integration. ([@palkan][])

Add `require "ruby-next/language/bootsnap"` after setting up Bootsnap
to transpile the files on load (and cache the resulted iseq via Bootsnap as usually).

- Do not patch `eval` and friends when using runtime mode. ([@palkan][])

Eval support should  be enabled explicitly via the `RubyNext::Language::Eval` refinement, 'cause we cannot handle all the edge cases easily (e.g., the usage caller's binding locals).

- Revoke method reference support. ([@palkan][])

You can still use this feature by enabling it explicitly (see Readme).

- Support in modifier. ([@palkan][])

```ruby
{a: 1, b: 2} in {a:, **}
p a #=> 1
```

## 0.1.0 (2019-11-18)

- Support hash pattern in array and vice versa. ([@palkan][])

- Handle multiple `-e` in `uby-next`. ([@palkan][])

## 0.1.0 (2019-11-16)

- Add pattern matching. ([@palkan][])

- Add numbered parameters. ([@palkan][])

- Add arguments forwarding. ([@palkan][])

- Add `Enumerable#filter_map`. ([@palkan][])

- Add `Enumerable#filter/filter!`. ([@palkan][])

- Add multiple arguments support to `Hash#merge`. ([@palkan][])

- Add `Array#intersection`, `Array#union`, `Array#difference`. ([@palkan][])

- Add `Enumerable#tally`. ([@palkan][])

- Implement gem integration flow. ([@palkan][])

  - Transpile code via `ruby-next nextify`.
  - Setup load path via `RubyNext::Language.setup_gem_load_Path`.

- Add `ruby-next nextify` command. ([@palkan][])

- Add endless Range support. ([@palkan][])

- Add method reference syntax support. ([@palkan][])

- Add `Proc#<<` and `Proc#>>`. ([@palkan][])

- Add `Kernel#then`. ([@palkan][])

[@palkan]: https://github.com/palkan
[backports]: https://github.com/marcandre/backports
[@sl4vr]: https://github.com/sl4vr
[@skryukov]: https://github.com/skryukov
