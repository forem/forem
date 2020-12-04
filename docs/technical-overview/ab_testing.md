# A/B testing

We use the [Field Test](https://github.com/ankane/field_test) gem for conducting simple A/B tests.

If you want to propose an A/B test of a feature, you may make a pull request
which defines the hypotheses and what admins should look for to declare a winner.
As A/B tests are going to have results that may differ from Forem to Forem, the
process is relatively immature. In the future we may have more studies that can return anonymous ecosystem-wide results.

A/B tests are inherently the most useful in _large_ Forems, where qualitative
feedback may be more useful on small Forems. As such, [DEV](https://dev.to)
is our largest Forem and therefore can provide us with the most feedback for
our existing A/B tests. However, we must keep in mind that DEV results may
not apply well to future large Forems. We should seek to re-run useful experiments within the ecosystem after time has passed.

## Creating a new A/B test

Follow the guidelines of the field test gem and add the test info to [config/field_test.yml](https://github.com/forem/forem/blob/master/config/field_test.yml).

Then where you want to trigger the variant, you'll add some code like this:

```ruby
  test_variant = field_test(:follow_implicit_points, participant: user)
  case test_variant
  when "no_implicit_score"
    0
  when "half_weight_after_log"
    Math.log(occurrences + bonus + 1) * 0.5
  when "double_weight_after_log"
    Math.log(occurrences + bonus + 1) * 2.0
  when "double_bonus_before_log"
    Math.log(occurrences + (bonus * 2) + 1)
  when "without_weighting_bonus"
    Math.log(occurrences + 1)
  else # base - Our current "default" implementation
    Math.log(occurrences + bonus + 1) # + 1 in all cases is to avoid log(0) => -infinity
  end
```

Which would find or create the test variant for that user in particular. If
this code is not called in the controller or view, you'll need to first
include the gem helpers at the top of the file...

```
include FieldTest::Helpers
```

To record a successful field test outcome, you should call something like this

```ruby
    Users::RecordFieldTestEventWorker
      .perform_async(user_id, :follow_implicit_points, "user_creates_reaction")
```

And modify that class as needed to determine whether to record the successful trial.