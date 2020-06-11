---
title: Regression Testing
---

# Regression Testing

Regression testing is a technique for detecting breaking changes over time in a
codebase.

Proper Regression testing is one of the most powerful tools in a programmer's
arsenal for avoiding the bugs that crop up as a project grows in size.

Generally speaking, Regression testing is accomplished by a combination of
[Acceptance tests][acceptance_tests] and [Integration tests][integration_tests]
performed on areas where bugs have been found in the past. As it happens,
software bugs tend to exist in groups; writing tests around buggy code will
almost always uncover new bugs as code evolves.

The practice of Regression testing usually takes place after code has been
written, and is used to detect if recent changes have introduced new bugs by
breaking previously functional software.

There is no perfect prescribed method for Regression testing, and it has evolved
with the introduction of [Continuous Integration][ci] practices like the ones
that DEV uses. However, CI doesn't replace the need for Regression testing.
Regression tests should still be added to the codebase when bugs are discovered.

If you submit a bug patch to the DEV application, you might be asked to write a
Regression test around your patch to help warn future DEV contributors if that
bug ever makes another appearance. This practice has the added benefit of
helping to ensure your patch fixes the bug.

[acceptance_tests]: /tests/acceptance-tests/
[integration_tests]: /tests/integration-tests/
[ci]: /deployment/

# [Percy](https://percy.io/)

Percy is a tool that can be used to do visual regression testing. Percy renders
and compares snapshots across browsers and screens to detect, highlight, and
group visual differences. This allows users to quickly find visual regression issues. Currently,
**Percy is inactive in our test suite** due to some integration issues. We are
not sure if we will try to reimplement it in the future so for now we have
decided to leave the code as is. You will notice `Percy.snapshot` being called
in multiple tests. That method has been stubbed in our `rails_helper.rb` file to ensure that
we don't waste resources taking snapshots. You will also notice some specs that
only take Percy snapshots have been commented out.
