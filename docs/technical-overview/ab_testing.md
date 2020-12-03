# A/B testing

We use the [Field Test](https://github.com/ankane/field_test) gem for conducting simple A/B tests.

If you want to propose an A/B test of a feature, you may make a pull request which defines the hypotheses and what admins should look for to declare a winner. As A/B tests are going to have results that may differ from Forem to Forem, the process is relatively immature. In the future we may have more studies that can return anonymous ecosystem-wide results.

A/B tests are inherently the most useful in _large_ Forems, where qualitative feedback may be more useful on small Forems. As such, [DEV](https://dev.to) is our largest Forem and therefore can provide us with the most feedback for our existing A/B tests. However, we must keep in mind that DEV results may not apply well to future large Forems. We should seek to re-run useful experiments within the ecosystem after time has passed.
