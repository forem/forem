Use the `--order` option to tell RSpec how to order the files, groups, and
examples. The available ordering schemes are `defined` and `rand`.

`defined` is the default, which executes groups and examples in the order they
are defined as the spec files are loaded, with the caveat that each group
runs its examples before running its nested example groups, even if the
nested groups are defined before the examples.

Use `rand` to randomize the order of groups and examples within the groups.
Nested groups are always run from top-level to bottom-level in order to avoid
executing `before(:context)` and `after(:context)` hooks more than once, but the
order of groups at each level is randomized.

With `rand` you can also specify a seed.

Use `recently-modified` to run the most recently modified files first. You can
combine it with `--only-failures` to find the most recent failing specs. Note
that `recently-modified` and `rand` are mutually exclusive.

## Example usage

The `defined` option is only necessary when you have `--order rand` stored in a
config file (e.g. `.rspec`) and you want to override it from the command line.

<pre><code class="bash">--order defined
--order rand
--order rand:123
--seed 123 # same as --order rand:123
--order recently-modified
</code></pre>
