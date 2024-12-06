# Changelog

### 5.7.0

* Performance improvement: don't run `rake knapsack_pro:rspec_test_example_detector` when no slow test files are detected for RSpec.

    https://github.com/KnapsackPro/knapsack_pro-ruby/pull/225

https://github.com/KnapsackPro/knapsack_pro-ruby/compare/v5.6.0...v5.7.0

### 5.6.0

* Use `frozen_string_literal: true` to reduce memory usage

    https://github.com/KnapsackPro/knapsack_pro-ruby/pull/220

* Enforce `frozen_string_literal: true` in the gem files with Rubocop

    https://github.com/KnapsackPro/knapsack_pro-ruby/pull/222

https://github.com/KnapsackPro/knapsack_pro-ruby/compare/v5.5.0...v5.6.0

### 5.5.0

* Detect user seats for AppVeyor, Codefresh, Codeship

    https://github.com/KnapsackPro/knapsack_pro-ruby/pull/221

https://github.com/KnapsackPro/knapsack_pro-ruby/compare/v5.4.1...v5.5.0

### 5.4.1

* Fixes RSpec conflict (see https://github.com/KnapsackPro/knapsack_pro-ruby/issues/217)

    https://github.com/KnapsackPro/knapsack_pro-ruby/pull/218

https://github.com/KnapsackPro/knapsack_pro-ruby/compare/v5.4.0...v5.4.1

### 5.4.0

* Send to the API the CI provider with a header

    https://github.com/KnapsackPro/knapsack_pro-ruby/pull/216

https://github.com/KnapsackPro/knapsack_pro-ruby/compare/v5.3.5...v5.4.0

### 5.3.5

* Handle RSpec exceptions when running RSpec in Queue Mode

    https://github.com/KnapsackPro/knapsack_pro-ruby/pull/214

    https://github.com/KnapsackPro/knapsack_pro-ruby/pull/215

https://github.com/KnapsackPro/knapsack_pro-ruby/compare/v5.3.4...v5.3.5

### 5.3.4

* fix(Queue Mode): handle OS signals and RSpec internal `wants_to_quit` and `rspec_is_quitting` states to stop consuming tests from the Queue API when the CI node is terminated

    https://github.com/KnapsackPro/knapsack_pro-ruby/pull/207

https://github.com/KnapsackPro/knapsack_pro-ruby/compare/v5.3.3...v5.3.4

### 5.3.3

* Fix hanging CI when `git fetch --shallow-since` takes too long

    https://github.com/KnapsackPro/knapsack_pro-ruby/pull/213

https://github.com/KnapsackPro/knapsack_pro-ruby/compare/v5.3.2...v5.3.3

### 5.3.2

* On top of 5.3.1, avoid noise to stderr when git is not available when collecting the build author

https://github.com/KnapsackPro/knapsack_pro-ruby/compare/v5.3.1...v5.3.2

### 5.3.1

* Avoid noise to stderr when git is not available when collecting authors

    https://github.com/KnapsackPro/knapsack_pro-ruby/pull/211

https://github.com/KnapsackPro/knapsack_pro-ruby/compare/v5.3.0...v5.3.1

### 5.3.0

* Perf: Send authors to the API only on the first request (for Queue Mode)

https://github.com/KnapsackPro/knapsack_pro-ruby/compare/v5.2.1...v5.3.0

### 5.2.1

* Shallow fetch the last month of commits only on CI
* Ensure input to `git shortlog`

    https://github.com/KnapsackPro/knapsack_pro-ruby/pull/209

https://github.com/KnapsackPro/knapsack_pro-ruby/compare/v5.2.0...v5.2.1

### 5.2.0

* Send authors to the API

    https://github.com/KnapsackPro/knapsack_pro-ruby/pull/208

https://github.com/KnapsackPro/knapsack_pro-ruby/compare/v5.1.2...v5.2.0

### 5.1.2

* Fix broken RSpec split by test examples feature when `SPEC_OPTS` is set in Queue Mode. Ignore `SPEC_OPTS` when generating test examples report for slow test files.

    https://github.com/KnapsackPro/knapsack_pro-ruby/pull/191

https://github.com/KnapsackPro/knapsack_pro-ruby/compare/v5.1.1...v5.1.2

### 5.1.1

* Use `KNAPSACK_PRO_FIXED_QUEUE_SPLIT=true` as default value in Queue Mode for GitLab CI

    https://github.com/KnapsackPro/knapsack_pro-ruby/pull/206

https://github.com/KnapsackPro/knapsack_pro-ruby/compare/v5.1.0...v5.1.1

### 5.1.0

* Mask user seats data instead of hashing it

    https://github.com/KnapsackPro/knapsack_pro-ruby/pull/202

https://github.com/KnapsackPro/knapsack_pro-ruby/compare/v5.0.0...v5.1.0


### 5.0.0

* __(breaking change)__ Use `KNAPSACK_PRO_FIXED_QUEUE_SPLIT=true` as default value in Queue Mode and use `false` for proper CI providers

    https://github.com/KnapsackPro/knapsack_pro-ruby/pull/198

* Detect CI from environment and get the correct ENVs instead of trying all of them and risk conflicts

    https://github.com/KnapsackPro/knapsack_pro-ruby/pull/201

    __(breaking change)__ for Buildkite. You need to pass the `BUILDKITE` environment variable to Docker Compose.

    https://github.com/KnapsackPro/knapsack_pro-ruby/issues/204

* Set `RAILS_ENV=test` / `RACK_ENV=test` in Queue Mode

    https://github.com/KnapsackPro/knapsack_pro-ruby/pull/199

https://github.com/KnapsackPro/knapsack_pro-ruby/compare/v4.1.0...v5.0.0

### 4.1.0

* Add support for CI node retry count on GitHub Actions

    __(breaking change)__ for open-source forked repositories using GitHub Actions. See a fix in PR description:

    https://github.com/KnapsackPro/knapsack_pro-ruby/pull/197

https://github.com/KnapsackPro/knapsack_pro-ruby/compare/v4.0.0...v4.1.0

### 4.0.0

* __(breaking change)__  Raise when `KNAPSACK_PRO_CI_NODE_BUILD_ID` is missing

    https://github.com/KnapsackPro/knapsack_pro-ruby/pull/195

https://github.com/KnapsackPro/knapsack_pro-ruby/compare/v3.11.0...v4.0.0

### 3.11.0

* Send distinguishable user seat info over to the API

    https://github.com/KnapsackPro/knapsack_pro-ruby/pull/192

https://github.com/KnapsackPro/knapsack_pro-ruby/compare/v3.10.0...v3.11.0

### 3.10.0

* Remove Solano CI and Snap CI support because they do not exist anymore

    https://github.com/KnapsackPro/knapsack_pro-ruby/pull/194

https://github.com/KnapsackPro/knapsack_pro-ruby/compare/v3.9.0...v3.10.0

### 3.9.0

* Suppress all RSpec spec file names displayed in stdout at the beginning of running tests in Regular Mode only when the log level is >= `warn`

    https://github.com/KnapsackPro/knapsack_pro-ruby/pull/190

https://github.com/KnapsackPro/knapsack_pro-ruby/compare/v3.8.0...v3.9.0

### 3.8.0

* Extract URLs and point them at `https://knapsackpro.com/perma/ruby/*`

    https://github.com/KnapsackPro/knapsack_pro-ruby/pull/187

https://github.com/KnapsackPro/knapsack_pro-ruby/compare/v3.7.0...v3.8.0

### 3.7.0

* Adjust the timer behaviour in the RSpec adapter

    https://github.com/KnapsackPro/knapsack_pro-ruby/pull/184

https://github.com/KnapsackPro/knapsack_pro-ruby/compare/v3.6.0...v3.7.0

### 3.6.0

* Add an attempt to read from the cache for Regular Mode API

    https://github.com/KnapsackPro/knapsack_pro-ruby/pull/182

https://github.com/KnapsackPro/knapsack_pro-ruby/compare/v3.5.0...v3.6.0

### 3.5.0

* Add the `KnapsackPro::Hooks::Queue.before_subset_queue` hook in Queue Mode

    https://github.com/KnapsackPro/knapsack_pro-ruby/pull/183

https://github.com/KnapsackPro/knapsack_pro-ruby/compare/v3.4.2...v3.5.0

### 3.4.2

* Fix: Load `rspec/core` in Regular Mode when using RSpec split by test examples feature

    https://github.com/KnapsackPro/knapsack_pro-ruby/pull/181

https://github.com/KnapsackPro/knapsack_pro-ruby/compare/v3.4.1...v3.4.2

### 3.4.1

* Improve the RSpec Queue Mode runner log output (add seed)

  https://github.com/KnapsackPro/knapsack_pro-ruby/pull/178

https://github.com/KnapsackPro/knapsack_pro-ruby/compare/v3.4.0...v3.4.1

### 3.4.0

* Update documentation and code because the encryption feature does not work with the RSpec split by examples feature

    Update docs: https://github.com/KnapsackPro/knapsack_pro-ruby/pull/176

    Update code: https://github.com/KnapsackPro/knapsack_pro-ruby/pull/177

https://github.com/KnapsackPro/knapsack_pro-ruby/compare/v3.3.1...v3.4.0

### 3.3.1

* Skip loading a test file path for Minitest in Queue Mode when it does not exist on the disk

    https://github.com/KnapsackPro/knapsack_pro-ruby/pull/174

https://github.com/KnapsackPro/knapsack_pro-ruby/compare/v3.3.0...v3.3.1

### 3.3.0

* Show a JSON report file content when RSpec fails during a dry run 

    https://github.com/KnapsackPro/knapsack_pro-ruby/pull/172

https://github.com/KnapsackPro/knapsack_pro-ruby/compare/v3.2.1...v3.3.0

### 3.2.1

* Raise exception when using `:focus` tag to avoid skipping RSpec tests

    https://github.com/KnapsackPro/knapsack_pro-ruby/pull/167

https://github.com/KnapsackPro/knapsack_pro-ruby/compare/v3.2.0...v3.2.1

### 3.2.0

* Add an error message to `KnapsackPro::Adapters::RspecAdapter#bind`

    https://github.com/KnapsackPro/knapsack_pro-ruby/pull/165

https://github.com/KnapsackPro/knapsack_pro-ruby/compare/v3.1.3...v3.2.0

### 3.1.3

* Run Fallback Mode when `Errno::ECONNRESET` exception happens

    https://github.com/KnapsackPro/knapsack_pro-ruby/pull/164

https://github.com/KnapsackPro/knapsack_pro-ruby/compare/v3.1.2...v3.1.3

### 3.1.2

* Fix bug when test files have no recorded time execution then they should not be detected as slow test files for RSpec split by test examples feature

    https://github.com/KnapsackPro/knapsack_pro-ruby/pull/163

https://github.com/KnapsackPro/knapsack_pro-ruby/compare/v3.1.1...v3.1.2

### 3.1.1

* Rephrase log outputs in the Queue Mode RSpec runner

    https://github.com/KnapsackPro/knapsack_pro-ruby/pull/160

https://github.com/KnapsackPro/knapsack_pro-ruby/compare/v3.1.0...v3.1.1

### 3.1.0

* Use `.knapsack_pro` directory for temporary files instead of the `tmp` directory in the user's project directory

    https://github.com/KnapsackPro/knapsack_pro-ruby/pull/155

https://github.com/KnapsackPro/knapsack_pro-ruby/compare/v3.0.0...v3.1.0

### 3.0.0

* __(breaking change)__ Remove support for RSpec 2.x. This change was already done by accident in [the pull request](https://github.com/KnapsackPro/knapsack_pro-ruby/pull/143) when we added the RSpec `context` hook, which is available only since RSpec 3.x.
* Use RSpec `example` block argument instead of the global `RSpec.current_example`. This allows to run tests with the `async-rspec` gem.

    https://github.com/KnapsackPro/knapsack_pro-ruby/pull/153

https://github.com/KnapsackPro/knapsack_pro-ruby/compare/v2.18.2...v3.0.0

### 2.18.2

* Track all test files assigned to a CI node in Regular Mode including pending test files in order to retry proper set of tests on the retried CI node

    https://github.com/KnapsackPro/knapsack_pro-ruby/pull/152

https://github.com/KnapsackPro/knapsack_pro-ruby/compare/v2.18.1...v2.18.2

### 2.18.1

* Ensure RSpec is loaded to check its version for RSpec split by test examples feature

    https://github.com/KnapsackPro/knapsack_pro-ruby/pull/151

https://github.com/KnapsackPro/knapsack_pro-ruby/compare/v2.18.0...v2.18.1

### 2.18.0

* Do not allow to use the RSpec tag option together with the RSpec split by test examples feature in knapsack_pro gem in Regular Mode 

    https://github.com/KnapsackPro/knapsack_pro-ruby/pull/148

https://github.com/KnapsackPro/knapsack_pro-ruby/compare/v2.17.0...v2.18.0

### 2.17.0

* Use Ruby 3 in development and add small improvements

    https://github.com/KnapsackPro/knapsack_pro-ruby/pull/147

https://github.com/KnapsackPro/knapsack_pro-ruby/compare/v2.16.0...v2.17.0

### 2.16.0

* Improve test time execution tracking for RSpec

    https://github.com/KnapsackPro/knapsack_pro-ruby/pull/145

https://github.com/KnapsackPro/knapsack_pro-ruby/compare/v2.15.0...v2.16.0

### 2.15.0

* Do not allow to use the RSpec tag option together with the RSpec split by test examples feature

    https://github.com/KnapsackPro/knapsack_pro-ruby/pull/139

https://github.com/KnapsackPro/knapsack_pro-ruby/compare/v2.14.0...v2.15.0

### 2.14.0

* Track time spend in RSpec context hook

    https://github.com/KnapsackPro/knapsack_pro-ruby/pull/143

https://github.com/KnapsackPro/knapsack_pro-ruby/compare/v2.13.0...v2.14.0

### 2.13.0

* Update FAQ links in `knapsack_pro` warnings and remove FAQ from readme

    https://github.com/KnapsackPro/knapsack_pro-ruby/pull/142

https://github.com/KnapsackPro/knapsack_pro-ruby/compare/v2.12.0...v2.13.0

### 2.12.0

* Use 0 seconds as a default test file time execution instead of 0.1s because Knapsack Pro API already accepts 0 seconds value

    https://github.com/KnapsackPro/knapsack_pro-ruby/pull/140

https://github.com/KnapsackPro/knapsack_pro-ruby/compare/v2.11.0...v2.12.0

### 2.11.0

* Verify test runner adapter bind method is called to track test files time execution and ensure `tmp/knapsack_pro` directory is not removed accidentally

    https://github.com/KnapsackPro/knapsack_pro-ruby/pull/137

https://github.com/KnapsackPro/knapsack_pro-ruby/compare/v2.10.1...v2.11.0

### 2.10.1

* Fix RSpec split by test examples feature broken by lazy generating of JSON report with test example ids

    https://github.com/KnapsackPro/knapsack_pro-ruby/pull/135

https://github.com/KnapsackPro/knapsack_pro-ruby/compare/v2.10.0...v2.10.1

### 2.10.0

* Add support for an attempt to connect to existing Queue on API side to reduce slow requests number

    https://github.com/KnapsackPro/knapsack_pro-ruby/pull/133

https://github.com/KnapsackPro/knapsack_pro-ruby/compare/v2.9.0...v2.10.0

### 2.9.0

* Use `Process.clock_gettime` to measure track execution time

    https://github.com/KnapsackPro/knapsack_pro-ruby/pull/132

https://github.com/KnapsackPro/knapsack_pro-ruby/compare/v2.8.0...v2.9.0

### 2.8.0

* More actionable error message when RSpec split by examples is not working due to RSpec dry-run failure

    https://github.com/KnapsackPro/knapsack_pro-ruby/pull/130

https://github.com/KnapsackPro/knapsack_pro-ruby/compare/v2.7.0...v2.8.0

### 2.7.0

* Add support for env var `KNAPSACK_PRO_TEST_FILE_LIST_SOURCE_FILE` to allow accepting file containing test files to run

    https://github.com/KnapsackPro/knapsack_pro-ruby/pull/129

https://github.com/KnapsackPro/knapsack_pro-ruby/compare/v2.6.0...v2.7.0

### 2.6.0

* Improve logger to show failed requests URL and when retry will happen

    https://github.com/KnapsackPro/knapsack_pro-ruby/pull/127

https://github.com/KnapsackPro/knapsack_pro-ruby/compare/v2.5.0...v2.6.0

### 2.5.0

* Add production branch to non encryptable branches names

    https://github.com/KnapsackPro/knapsack_pro-ruby/pull/126

https://github.com/KnapsackPro/knapsack_pro-ruby/compare/v2.4.0...v2.5.0

### 2.4.0

* Update list of non encryptable branches

    https://github.com/KnapsackPro/knapsack_pro-ruby/pull/125

https://github.com/KnapsackPro/knapsack_pro-ruby/compare/v2.3.0...v2.4.0

### 2.3.0

* When you use Regular Mode then try 6 attempts to connect to the API instead of 3 attempts

    Add `KNAPSACK_PRO_MAX_REQUEST_RETRIES` environment variable to let user define their own number of request retries to the API. It is useful to set it to `0` for [forked repos](https://knapsackpro.com/faq/question/how-to-make-knapsack_pro-works-for-forked-repositories-of-my-project) when you want to rely on Fallback Mode.

    https://github.com/KnapsackPro/knapsack_pro-ruby/pull/124

https://github.com/KnapsackPro/knapsack_pro-ruby/compare/v2.2.1...v2.3.0

### 2.2.1

* Improve detection of test file path in test-unit runner for test files with shared examples

    https://github.com/KnapsackPro/knapsack_pro-ruby/pull/123

https://github.com/KnapsackPro/knapsack_pro-ruby/compare/v2.2.0...v2.2.1

### 2.2.0

* Allow defining Queue Mode hooks multiple times (`KnapsackPro::Hooks::Queue.before_queue`, `KnapsackPro::Hooks::Queue.after_subset_queue`, `KnapsackPro::Hooks::Queue.after_queue`)

    https://github.com/KnapsackPro/knapsack_pro-ruby/pull/122

https://github.com/KnapsackPro/knapsack_pro-ruby/compare/v2.1.1...v2.2.0

### 2.1.1

* Explicitly call root test runner class to avoid a confusing error when test runner gem is not loaded

    https://github.com/KnapsackPro/knapsack_pro-ruby/pull/120

https://github.com/KnapsackPro/knapsack_pro-ruby/compare/v2.1.0...v2.1.1

### 2.1.0

* Add `KNAPSACK_PRO_RSPEC_TEST_EXAMPLE_DETECTOR_PREFIX` to customize prefix for generating test examples report when using RSpec split by test examples

    https://github.com/KnapsackPro/knapsack_pro-ruby/pull/118

https://github.com/KnapsackPro/knapsack_pro-ruby/compare/v2.0.0...v2.1.0

### 2.0.0

* Add support for CI build ID for Github Actions

    https://github.com/KnapsackPro/knapsack_pro-ruby/pull/116

    __Migration path for Github Actions users - required__

    If you use Github Actions and Knapsack Pro Queue Mode then you must set in Github Actions environment variable: `KNAPSACK_PRO_FIXED_QUEUE_SPLIT=true`. Thanks to that when you retry CI build then tests will run based on previously recorded tests. This solves problem mentioned in the [PR](https://github.com/KnapsackPro/knapsack_pro-ruby/pull/116).

    __Migration path for other users__ - just update `knapsack_pro` gem. Nothing to change in your code :)

https://github.com/KnapsackPro/knapsack_pro-ruby/compare/v1.22.3...v2.0.0

### 1.22.3

* Support for non-delimited formatting params of RSpec like `-fMyCustomFormatter`

    https://github.com/KnapsackPro/knapsack_pro-ruby/pull/115

https://github.com/KnapsackPro/knapsack_pro-ruby/compare/v1.22.2...v1.22.3

### 1.22.2

* Log when next retry request to Knapsack Pro API happens before starting Fallback Mode

    https://github.com/KnapsackPro/knapsack_pro-ruby/pull/114

https://github.com/KnapsackPro/knapsack_pro-ruby/compare/v1.22.1...v1.22.2

### 1.22.1

* Fix for an auto split of slow RSpec test files by test examples when using `KNAPSACK_PRO_RSPEC_SPLIT_BY_TEST_EXAMPLES=true` and `parallel_tests` gem. Save the JSON reports with unique file names with the CI node index in the name to avoid accidentally overriding the files on the same disk.

    https://github.com/KnapsackPro/knapsack_pro-ruby/pull/113

https://github.com/KnapsackPro/knapsack_pro-ruby/compare/v1.22.0...v1.22.1

### 1.22.0

* Increase request retry timebox from 4s to 8s to not flood Knapsack Pro API with too many requests in a short period of time and to give time for API server to autoscale and add additional machines to serve traffic
* When Fallback Mode is disabled with env `KNAPSACK_PRO_FALLBACK_MODE_ENABLED=false` then retry the request to Knapsack Pro API for 6 times instead of only 3 times.

  Here is related [info why some users want to disable Fallback Mode](https://github.com/KnapsackPro/knapsack_pro-ruby#required-ci-configuration-if-you-use-retry-single-failed-ci-node-feature-on-your-ci-server-when-knapsack_pro_fixed_queue_splittrue-in-queue-mode-or-knapsack_pro_fixed_test_suite_splittrue-in-regular-mode).

    https://github.com/KnapsackPro/knapsack_pro-ruby/pull/112

https://github.com/KnapsackPro/knapsack_pro-ruby/compare/v1.21.0...v1.22.0

### 1.21.0

* Automatically detect slow test files for RSpec and split them by test examples when `KNAPSACK_PRO_RSPEC_SPLIT_BY_TEST_EXAMPLES=true`
* Add slow test file pattern `KNAPSACK_PRO_SLOW_TEST_FILE_PATTERN` to define RSpec slow test files that should be split by test examples
* Start sending API token in header `KNAPSACK-PRO-TEST-SUITE-TOKEN` instead of a key `test_suite_token` in JSON payload.

    https://github.com/KnapsackPro/knapsack_pro-ruby/pull/106

https://github.com/KnapsackPro/knapsack_pro-ruby/compare/v1.20.2...v1.21.0

### 1.20.2

* Raise an error when running Cucumber in Queue Mode and Cucumber system process doesn't finish execution correctly (for instance Cucumber process was killed by CI server due to lack of memory)

    https://github.com/KnapsackPro/knapsack_pro-ruby/pull/111

https://github.com/KnapsackPro/knapsack_pro-ruby/compare/v1.20.1...v1.20.2

### 1.20.1

* Fix bug in RSpec split by test examples in < RSpec 3.6.0 (related to custom json formatter)

    https://github.com/KnapsackPro/knapsack_pro-ruby/pull/105

https://github.com/KnapsackPro/knapsack_pro-ruby/compare/v1.20.0...v1.20.1

### 1.20.0

* Add support for tests split by test examples to RSpec older than 3.6.0

    https://github.com/KnapsackPro/knapsack_pro-ruby/pull/104

https://github.com/KnapsackPro/knapsack_pro-ruby/compare/v1.19.0...v1.20.0

### 1.19.0

* RSpec split test files by test examples (by individual `it`s)

    https://github.com/KnapsackPro/knapsack_pro-ruby/pull/102

    __Note:__ See [PR](https://github.com/KnapsackPro/knapsack_pro-ruby/pull/102) for more details. This is an experimental feature and it may not work for very large test suite.

    __How to use it__: In order to split RSpec test files by test examples across parallel CI nodes you need to set flag:

    ```
    KNAPSACK_PRO_RSPEC_SPLIT_BY_TEST_EXAMPLES=true
    ```

    Thanks to that your CI build speed can be faster. We recommend using this feature with Queue Mode to ensure parallel CI nodes finish work at a similar time which gives you the shortest CI build time.

    Doing tests split by test examples can generate a lot of logs by `knapsack_pro` gem in Queue Mode. We recommend to set log level to:

    ```
    KNAPSACK_PRO_LOG_LEVEL=warn
    ```

https://github.com/KnapsackPro/knapsack_pro-ruby/compare/v1.18.2...v1.19.0

### 1.18.2

* If `KnapsackPro::Hooks::Queue.before_queue` hook has block of code that raises an exception then ensure the hook was called only once.

    https://github.com/KnapsackPro/knapsack_pro-ruby/pull/103

https://github.com/KnapsackPro/knapsack_pro-ruby/compare/v1.18.1...v1.18.2

### 1.18.1

* Pass non zero exit status from Cucumber as exit status for Cucumber executed in Queue Mode

    https://github.com/KnapsackPro/knapsack_pro-ruby/pull/101

https://github.com/KnapsackPro/knapsack_pro-ruby/compare/v1.18.0...v1.18.1

### 1.18.0

* __IMPORTANT__ Do not allow Fallback Mode when the CI node was retried to avoid running the wrong set of tests

    Please read the PR description if you are using retry failed CI node feature on your CI (for instance you use Buildkite).

    https://github.com/KnapsackPro/knapsack_pro-ruby/pull/100

* Increase delay between request retry to Knapsack Pro API from 2s to 4s for 2nd request and from 4s to 8s for 3rd request

    https://github.com/KnapsackPro/knapsack_pro-ruby/pull/99

https://github.com/KnapsackPro/knapsack_pro-ruby/compare/v1.17.0...v1.18.0

### 1.17.0

* Add `KNAPSACK_PRO_CUCUMBER_QUEUE_PREFIX` to allow run Cucumber with spring gem in Queue Mode

    https://github.com/KnapsackPro/knapsack_pro-ruby/pull/98

https://github.com/KnapsackPro/knapsack_pro-ruby/compare/v1.16.1...v1.17.0

### 1.16.1

* Allow to use Queue Mode for old RSpec versions that don't have `RSpec.configuration.reset_filters` method

    https://github.com/KnapsackPro/knapsack_pro-ruby/pull/96

https://github.com/KnapsackPro/knapsack_pro-ruby/compare/v1.16.0...v1.16.1

### 1.16.0

* Add test runner name to `KNAPSACK-PRO-CLIENT-NAME` header send to Knapsack Pro API

    https://github.com/KnapsackPro/knapsack_pro-ruby/pull/95

https://github.com/KnapsackPro/knapsack_pro-ruby/compare/v1.15.0...v1.16.0

### 1.15.0

* Add support for Codefresh.io CI provider

    https://github.com/KnapsackPro/knapsack_pro-ruby/pull/92

https://github.com/KnapsackPro/knapsack_pro-ruby/compare/v1.14.0...v1.15.0

### 1.14.0

* Add support for GitHub Actions

    https://github.com/KnapsackPro/knapsack_pro-ruby/pull/90

https://github.com/KnapsackPro/knapsack_pro-ruby/compare/v1.13.0...v1.14.0

### 1.13.0

* Add support for job index and job count for parallelism in Semaphore 2.0

    https://github.com/KnapsackPro/knapsack_pro-ruby/pull/89

https://github.com/KnapsackPro/knapsack_pro-ruby/compare/v1.12.1...v1.13.0

### 1.12.1

* Use `CI_PIPELINE_ID` as build ID for GitLab CI because it is unique across parallel jobs
* Load GitLab CI first to avoid edge case with order of loading envs for `CI_NODE_INDEX`

    https://github.com/KnapsackPro/knapsack_pro-ruby/pull/88

https://github.com/KnapsackPro/knapsack_pro-ruby/compare/v1.12.0...v1.12.1

### 1.12.0

* Add Queue Mode for Cucumber

    https://github.com/KnapsackPro/knapsack_pro-ruby/pull/87

https://github.com/KnapsackPro/knapsack_pro-ruby/compare/v1.11.0...v1.12.0

### 1.11.0

* Add support for `KNAPSACK_PRO_TEST_FILE_LIST` environment variable to run explicitly listed tests

    https://github.com/KnapsackPro/knapsack_pro-ruby/pull/86

https://github.com/KnapsackPro/knapsack_pro-ruby/compare/v1.10.1...v1.11.0

### 1.10.1

* Fix log info when measured time of tests was lost

    https://github.com/KnapsackPro/knapsack_pro-ruby/pull/85

https://github.com/KnapsackPro/knapsack_pro-ruby/compare/v1.10.0...v1.10.1

### 1.10.0

* Logs error on lost info about recorded timing for test files due to missing json files in Queue Mode

    https://github.com/KnapsackPro/knapsack_pro-ruby/pull/83

* Fix bug: default test file time should not be added to measured time

    https://github.com/KnapsackPro/knapsack_pro-ruby/pull/84

https://github.com/KnapsackPro/knapsack_pro-ruby/compare/v1.9.0...v1.10.0

### 1.9.0

* Reduce data transfer and speed up usage of Knapsack Pro API for Queue Mode

    https://github.com/KnapsackPro/knapsack_pro-ruby/pull/81

https://github.com/KnapsackPro/knapsack_pro-ruby/compare/v1.8.0...v1.9.0

### 1.8.0

* Run Fallback Mode when `OpenSSL::SSL::SSLError` certificate verify failed for API

    https://github.com/KnapsackPro/knapsack_pro-ruby/pull/80

https://github.com/KnapsackPro/knapsack_pro-ruby/compare/v1.7.0...v1.8.0

### 1.7.0

* Add `KNAPSACK_PRO_LOG_DIR` to set directory where to write logs

    https://github.com/KnapsackPro/knapsack_pro-ruby/pull/79

https://github.com/KnapsackPro/knapsack_pro-ruby/compare/v1.6.0...v1.7.0

### 1.6.0

* Retry request 3 times when API returns 5xx HTTP status

    https://github.com/KnapsackPro/knapsack_pro-ruby/pull/78

https://github.com/KnapsackPro/knapsack_pro-ruby/compare/v1.5.0...v1.6.0

### 1.5.0

* Add support for Semaphore CI 2.0

    https://github.com/KnapsackPro/knapsack_pro-ruby/pull/77

https://github.com/KnapsackPro/knapsack_pro-ruby/compare/v1.4.0...v1.5.0

### 1.4.0

* Use .test domain for development mode

    https://github.com/KnapsackPro/knapsack_pro-ruby/pull/76

https://github.com/KnapsackPro/knapsack_pro-ruby/compare/v1.3.0...v1.4.0

### 1.3.0

* Add metadata to the gemspec

https://github.com/KnapsackPro/knapsack_pro-ruby/compare/v1.2.1...v1.3.0

### 1.2.1

* Run Fallback Mode for exception `Errno::EPIPE`

    https://github.com/KnapsackPro/knapsack_pro-ruby/pull/75

https://github.com/KnapsackPro/knapsack_pro-ruby/compare/v1.2.0...v1.2.1

### 1.2.0

* Add support for GitLab CI env vars CI_NODE_TOTAL and CI_NODE_INDEX.

    https://github.com/KnapsackPro/knapsack_pro-ruby/pull/73

https://github.com/KnapsackPro/knapsack_pro-ruby/compare/v1.1.0...v1.2.0

### 1.1.0

* Add test file exclude pattern.

    https://github.com/KnapsackPro/knapsack_pro-ruby/pull/72

https://github.com/KnapsackPro/knapsack_pro-ruby/compare/v1.0.2...v1.1.0

### 1.0.2

* Track time execution of all tests assigned to CI node in Queue Mode even when they did not run due syntax error or being pending/empty in test run.

    https://github.com/KnapsackPro/knapsack_pro-ruby/pull/71

https://github.com/KnapsackPro/knapsack_pro-ruby/compare/v1.0.1...v1.0.2

### 1.0.1

* Fix bug with not being able to set log level via logger wrapper.

    https://github.com/KnapsackPro/knapsack_pro-ruby/pull/70

https://github.com/KnapsackPro/knapsack_pro-ruby/compare/v1.0.0...v1.0.1

### 1.0.0

* Release 1.0.0 is backward compatible with all previous releases.
* Run tests in Fallback Mode when API response is 5xx

    https://github.com/KnapsackPro/knapsack_pro-ruby/pull/69

https://github.com/KnapsackPro/knapsack_pro-ruby/compare/v0.57.0...v1.0.0

### 0.57.0

* Add support for Solano CI and AppVeyor

    https://github.com/KnapsackPro/knapsack_pro-ruby/pull/66

https://github.com/KnapsackPro/knapsack_pro-ruby/compare/v0.56.0...v0.57.0

### 0.56.0

* Add support for Cirrus CI

    https://github.com/KnapsackPro/knapsack_pro-ruby/pull/65

https://github.com/KnapsackPro/knapsack_pro-ruby/compare/v0.55.2...v0.56.0

### 0.55.2

* Remove recursion in Queue Mode

    https://github.com/KnapsackPro/knapsack_pro-ruby/pull/64

https://github.com/KnapsackPro/knapsack_pro-ruby/compare/v0.55.1...v0.55.2

### 0.55.1

* Switch to fallback mode when failed to open TCP connection to API

    https://github.com/KnapsackPro/knapsack_pro-ruby/pull/63

https://github.com/KnapsackPro/knapsack_pro-ruby/compare/v0.55.0...v0.55.1

### 0.55.0

* Fix to record proper time for around(:each) in RSpec

    https://github.com/KnapsackPro/knapsack_pro-ruby/pull/62

https://github.com/KnapsackPro/knapsack_pro-ruby/compare/v0.54.0...v0.55.0

### 0.54.0

* Add Queue Mode for Minitest

    https://github.com/KnapsackPro/knapsack_pro-ruby/pull/60

https://github.com/KnapsackPro/knapsack_pro-ruby/compare/v0.53.0...v0.54.0

### 0.53.0

* Add support for Heroku CI environment variables.

    https://github.com/KnapsackPro/knapsack_pro-ruby/pull/55

https://github.com/KnapsackPro/knapsack_pro-ruby/compare/v0.52.0...v0.53.0

### 0.52.0

* Add support for Cucumber 3.

    https://github.com/KnapsackPro/knapsack_pro-ruby/pull/54

https://github.com/KnapsackPro/knapsack_pro-ruby/compare/v0.51.0...v0.52.0

### 0.51.0

* Add support for test-unit test runner.

    https://github.com/KnapsackPro/knapsack_pro-ruby/pull/53

https://github.com/KnapsackPro/knapsack_pro-ruby/compare/v0.50.1...v0.51.0

### 0.50.1

* Update RSpec timing adapter to be more resilient.

    https://github.com/KnapsackPro/knapsack_pro-ruby/pull/52

https://github.com/KnapsackPro/knapsack_pro-ruby/compare/v0.50.0...v0.50.1

### 0.50.0

* Add support for Codeship environment variables.

    https://github.com/KnapsackPro/knapsack_pro-ruby/pull/51

https://github.com/KnapsackPro/knapsack_pro-ruby/compare/v0.49.0...v0.50.0

### 0.49.0

* Show short warning for not executed test files on CI node. Show explanation in debug logs.

    https://github.com/KnapsackPro/knapsack_pro-ruby/pull/50

https://github.com/KnapsackPro/knapsack_pro-ruby/compare/v0.48.0...v0.49.0

### 0.48.0

* Fallback mode for Queue Mode when Knapsack Pro API doesn't work.

    https://github.com/KnapsackPro/knapsack_pro-ruby/pull/49

https://github.com/KnapsackPro/knapsack_pro-ruby/compare/v0.47.0...v0.48.0

### 0.47.0

* Add in Queue Mode the RSpec summary with info about examples, failures and pending tests.
* Fix not working message `Global time execution for tests` at end of each subset of tests from work queue.

    https://github.com/KnapsackPro/knapsack_pro-ruby/pull/48

https://github.com/KnapsackPro/knapsack_pro-ruby/compare/v0.46.0...v0.47.0

### 0.46.0

* Autoload knapsack_pro rake tasks with Rails Railties.

    https://github.com/KnapsackPro/knapsack_pro-ruby/pull/47

https://github.com/KnapsackPro/knapsack_pro-ruby/compare/v0.45.0...v0.46.0

### 0.45.0

* Add before and after queue hooks

    https://github.com/KnapsackPro/knapsack_pro-ruby/pull/46

https://github.com/KnapsackPro/knapsack_pro-ruby/compare/v0.44.0...v0.45.0

### 0.44.0

* Add ability to set test_dir using an environment variable.

    https://github.com/KnapsackPro/knapsack_pro-ruby/pull/45

https://github.com/KnapsackPro/knapsack_pro-ruby/compare/v0.43.0...v0.44.0

### 0.43.0

* Extract correct test directory from test file pattern that has multiple patterns.

    https://github.com/KnapsackPro/knapsack_pro-ruby/pull/43

https://github.com/KnapsackPro/knapsack_pro-ruby/compare/v0.42.0...v0.43.0

### 0.42.0

* Clear RSpec examples without shared examples in similar way as in RSpec 3.6.0

    https://github.com/KnapsackPro/knapsack_pro-ruby/pull/42

https://github.com/KnapsackPro/knapsack_pro-ruby/compare/v0.41.0...v0.42.0

### 0.41.0

* Add after subset queue hook and example how to use JUnit formatter in Queue Mode.

    https://github.com/KnapsackPro/knapsack_pro-ruby/pull/41

https://github.com/KnapsackPro/knapsack_pro-ruby/compare/v0.40.0...v0.41.0

### 0.40.0

* Replace rake task installer `knapsack_pro:install` with online installation guide. Remove `tty-prompt` gem dependency.

    https://github.com/KnapsackPro/knapsack_pro-ruby/pull/39

https://github.com/KnapsackPro/knapsack_pro-ruby/compare/v0.39.0...v0.40.0

### 0.39.0

* Remove timecop gem from required dependencies list.

    https://github.com/KnapsackPro/knapsack_pro-ruby/pull/38

https://github.com/KnapsackPro/knapsack_pro-ruby/compare/v0.38.0...v0.39.0

### 0.38.0

* Add support for Gitlab CI.

    https://github.com/KnapsackPro/knapsack_pro-ruby/pull/36

* More info about Buildkite in installer.
* More info about CircleCI in installer.

https://github.com/KnapsackPro/knapsack_pro-ruby/compare/v0.37.0...v0.38.0

### 0.37.0

* Add another explanation why test files could not be executed on CI node in Queue Mode.

    https://github.com/KnapsackPro/knapsack_pro-ruby/pull/34

* Show better explanation what to do when there is missing test suite token environment variable.

    https://github.com/KnapsackPro/knapsack_pro-ruby/pull/35

https://github.com/KnapsackPro/knapsack_pro-ruby/compare/v0.36.0...v0.37.0

### 0.36.0

* Show messages about not executed test files as warnings in logs.
* Handle case when start timer was not called (rspec-retry issue).

    https://github.com/KnapsackPro/knapsack_pro-ruby/pull/33

https://github.com/KnapsackPro/knapsack_pro-ruby/compare/v0.35.0...v0.36.0

### 0.35.0

* Add `RSpecQueueProfileFormatterExtension` to show profile summary only once at the very end of RSpec Queue Mode output.

https://github.com/KnapsackPro/knapsack_pro-ruby/compare/v0.34.0...v0.35.0

### 0.34.0

* Fix command visible at the end of RSpec Queue Mode output to be able retry test files with spaces in name.
* Fix command visible at the end of RSpec Queue Mode output to be able retry test files without RSpecQueueSummaryFormatter which is dedicated only for Queue Mode.

https://github.com/KnapsackPro/knapsack_pro-ruby/compare/v0.33.0...v0.34.0

### 0.33.0

* Add RSpec Queue Formatter to hide duplicated pending and failed tests in Queue Mode

  You can keep duplicated pending/failed summary with flag `KNAPSACK_PRO_MODIFY_DEFAULT_RSPEC_FORMATTERS`. More can be found in read me.

    https://github.com/KnapsackPro/knapsack_pro-ruby/pull/31

https://github.com/KnapsackPro/knapsack_pro-ruby/compare/v0.32.0...v0.33.0

### 0.32.0

* Add encryption for branch names

    https://github.com/KnapsackPro/knapsack_pro-ruby/pull/30

https://github.com/KnapsackPro/knapsack_pro-ruby/compare/v0.31.0...v0.32.0

### 0.31.0

* Add supported for log levels `fatal` and `error` by `KNAPSACK_PRO_LOG_LEVEL` environment variable.
* Allow `KNAPSACK_PRO_LOG_LEVEL` case insensitive.
* Move all messages related to requests to Knapsack Pro API in log `debug` level and keep `info` level only for important messages like how to retry tests in development or info why something works this way or the other (for instance why tests were not executed on the CI node).

    https://github.com/KnapsackPro/knapsack_pro-ruby/pull/29

https://github.com/KnapsackPro/knapsack_pro-ruby/compare/v0.30.0...v0.31.0

### 0.30.0

* Update license to MIT.

https://github.com/KnapsackPro/knapsack_pro-ruby/compare/v0.29.0...v0.30.0

### 0.29.0

* Add info about Jenkins to installer.
* Extend info about final step in installer about verification if first test suite run was recorded correctly.

https://github.com/KnapsackPro/knapsack_pro-ruby/compare/v0.28.1...v0.29.0

### 0.28.1

* Add support for test files in directory with spaces.

    https://github.com/KnapsackPro/knapsack_pro-ruby/issues/27

https://github.com/KnapsackPro/knapsack_pro-ruby/compare/v0.28.0...v0.28.1

### 0.28.0

* Show at the end of `knapsack_pro:queue:rspec` command the example how to run all tests executed for the CI node in the development environment.
* Show for each intermediate request to Knapsack Pro API queue how to run a subset of tests fetched from API.

https://github.com/KnapsackPro/knapsack_pro-ruby/compare/v0.27.0...v0.28.0

### 0.27.0

* Save build subset to API even when no test files were executed on CI node. Add warnings to notify why the test files were not executed on CI node in particular mode: regular or queue mode.

https://github.com/KnapsackPro/knapsack_pro-ruby/compare/v0.26.0...v0.27.0

### 0.26.0

* Add info how to allow FakeWeb to connect with Knapsack Pro API in install rake task.

https://github.com/KnapsackPro/knapsack_pro-ruby/compare/v0.25.0...v0.26.0

### 0.25.0

* Queue mode retry (remember queue split on retry CI node).

    https://github.com/KnapsackPro/knapsack_pro-ruby/pull/22

* Fix bug in queue mode with recording test files time execution data. Previously the same test files time execution data where multiple times send to Knapsack Pro API.

    https://github.com/KnapsackPro/knapsack_pro-ruby/pull/23

https://github.com/KnapsackPro/knapsack_pro-ruby/compare/v0.24.0...v0.25.0

### 0.24.0

* Send client name and version in headers for each request to Knapsack Pro API.

https://github.com/KnapsackPro/knapsack_pro-ruby/compare/v0.23.0...v0.24.0

### 0.23.0

* Add info about Queue Mode to install rake task.

https://github.com/KnapsackPro/knapsack_pro-ruby/compare/v0.22.0...v0.23.0

### 0.22.0

*  Add more info how to set up VCR and webmock to `knapsack_pro:install` rake task.

https://github.com/KnapsackPro/knapsack_pro-ruby/compare/v0.21.0...v0.22.0

### 0.21.0

* Improve VCR config documentation so it's more clear that ignore_hosts takes arguments instead of array

https://github.com/KnapsackPro/knapsack_pro-ruby/compare/v0.20.0...v0.21.0

### 0.20.0

* Wait a few seconds before retrying failed request to API. With each retry wait a bit longer. Retry at most 5 times.

https://github.com/KnapsackPro/knapsack_pro-ruby/compare/v0.19.0...v0.20.0

### 0.19.0

* Change timeout to 30s for requests to API.
* Retry failed request to API at most 3 times.

https://github.com/KnapsackPro/knapsack_pro-ruby/compare/v0.18.0...v0.19.0

### 0.18.0

* Add support for knapsack_pro queue mode

    https://github.com/KnapsackPro/knapsack_pro-ruby/pull/20

https://github.com/KnapsackPro/knapsack_pro-ruby/compare/v0.17.0...v0.18.0

### 0.17.0

* Enable fallback mode for SocketError when failed to open TCP connection to http or https API endpoint.

### 0.16.0

* Add KNAPSACK_PRO_LOG_LEVEL option

    Related PR:
    https://github.com/ArturT/knapsack/pull/49

https://github.com/KnapsackPro/knapsack_pro-ruby/compare/v0.15.2...v0.16.0

### 0.15.2

* Cache API response test file paths to fix problem with double request to get test suite distribution for the node.

https://github.com/KnapsackPro/knapsack_pro-ruby/compare/v0.15.1...v0.15.2

### 0.15.1

* Fix support for turnip >= 2.x

    Related PR:
    https://github.com/ArturT/knapsack/pull/47

https://github.com/KnapsackPro/knapsack_pro-ruby/compare/v0.15.0...v0.15.1

### 0.15.0

* Handle case when API returns no test files to execute on the node.

    https://github.com/KnapsackPro/knapsack_pro-ruby/pull/19

https://github.com/KnapsackPro/knapsack_pro-ruby/compare/v0.14.0...v0.15.0

### 0.14.0

* Use rake invoke for rspec and cucumber tasks.

https://github.com/KnapsackPro/knapsack_pro-ruby/compare/v0.13.0...v0.14.0

### 0.13.0

* Add installer to get started with the knapsack_pro gem.

https://github.com/KnapsackPro/knapsack_pro-ruby/compare/v0.12.0...v0.13.0

### 0.12.0

* Add support for Minitest::SharedExamples

    Related PR:
    https://github.com/ArturT/knapsack/pull/46

https://github.com/KnapsackPro/knapsack_pro-ruby/compare/v0.11.0...v0.12.0

### 0.11.0

* Add test file names encryption

https://github.com/KnapsackPro/knapsack_pro-ruby/compare/v0.10.0...v0.11.0

### 0.10.0

* Add new environment variable `KNAPSACK_PRO_FIXED_TEST_SUITE_SPLIT`. The default value is true.

    It means when you run test suite again for the same commit hash and total number of nodes and for the same branch
    then you will get exactly the same test suite split.
    This is the new default behavior for the knapsack_pro gem. Thanks to that when tests on one of your node failed
    you can retry the node with exactly the same subset of tests that were run on the node in the first place.

    There is one edge case. When you run tests for the first time and there is no data collected about time execution of your tests then
    we need to collect data to prepare the first test suite split. The second run of your tests will have fixed test suite split.
    To compare if all your CI nodes are running based on the same test suite split seed you can check the value for seed in knapsack logging message
    before your test starts. The message looks like:

        [knapsack_pro] Test suite split seed: 8a606431-02a1-4766-9878-0ea42a07ad21

  * Show test suite split seed in logger based on `build_distribution_id` from Knapsack Pro API.
  * Send `fixed_test_suite_split` param to build distribution Knapsack Pro API endpoint.

  Related issues:

  * https://github.com/KnapsackPro/knapsack_pro-ruby/issues/15
  * https://github.com/KnapsackPro/knapsack_pro-ruby/issues/12

https://github.com/KnapsackPro/knapsack_pro-ruby/compare/v0.9.0...v0.10.0

### 0.9.0

* Add https support for Knapsack Pro API endpoint

    https://github.com/KnapsackPro/knapsack_pro-ruby/pull/14

https://github.com/KnapsackPro/knapsack_pro-ruby/compare/v0.8.0...v0.9.0

### 0.8.0

* Add Spinach support

    https://github.com/KnapsackPro/knapsack_pro-ruby/pull/11

https://github.com/KnapsackPro/knapsack_pro-ruby/compare/v0.7.2...v0.8.0

### 0.7.2

* Preserve cucumber latest error message with exit code to fix problem with false positive cucumber failed tests

    https://github.com/KnapsackPro/knapsack_pro-ruby/pull/10

https://github.com/KnapsackPro/knapsack_pro-ruby/compare/v0.7.1...v0.7.2

### 0.7.1

* Don't fail when there are no tests to run on a node

    https://github.com/KnapsackPro/knapsack_pro-ruby/issues/7
    https://github.com/KnapsackPro/knapsack_pro-ruby/pull/9

https://github.com/KnapsackPro/knapsack_pro-ruby/compare/v0.7.0...v0.7.1

### 0.7.0

* Add support for older cucumber versions than 1.3

    https://github.com/KnapsackPro/knapsack_pro-ruby/issues/5

https://github.com/KnapsackPro/knapsack_pro-ruby/compare/v0.6.1...v0.7.0

### 0.6.1

* Changed rake task in minitest_runner.rb to have no warnings output

    https://github.com/KnapsackPro/knapsack_pro-ruby/pull/4

https://github.com/KnapsackPro/knapsack_pro-ruby/compare/v0.6.0...v0.6.1

### 0.6.0

* Add support for Cucumber 2

https://github.com/KnapsackPro/knapsack_pro-ruby/compare/v0.5.0...v0.6.0

### 0.5.0

* Remove active support dependency so knapsack_pro gem can be used with rails 2.

https://github.com/KnapsackPro/knapsack_pro-ruby/compare/v0.4.0...v0.5.0

### 0.4.0

* Add support for snap-ci.com

https://github.com/KnapsackPro/knapsack_pro-ruby/compare/v0.3.0...v0.4.0

### 0.3.0

* Remove keyword arguments in order to add support for old ruby versions.

https://github.com/KnapsackPro/knapsack_pro-ruby/compare/v0.2.1...v0.3.0

### 0.2.1

* TestFileFinder should find unique files without duplicates when using test file pattern supporting symlinks
* Update test file pattern to support symlinks in specs and readme examples
* Backwards compatibility with knapsack gem old rspec adapter name

https://github.com/KnapsackPro/knapsack_pro-ruby/compare/v0.2.0...v0.2.1

### 0.2.0

* Change file path patterns to support 1-level symlinks by default

    https://github.com/KnapsackPro/knapsack_pro-ruby/pull/2

https://github.com/KnapsackPro/knapsack_pro-ruby/compare/v0.1.2...v0.2.0

### 0.1.2

* Fix Travis CI environment variables support

    https://github.com/KnapsackPro/knapsack_pro-ruby/pull/1

https://github.com/KnapsackPro/knapsack_pro-ruby/compare/v0.1.1...v0.1.2

### 0.1.1

* Make knapsack_pro backwards compatible with earlier version of minitest

    Related PR from knapsack gem repository:
    https://github.com/ArturT/knapsack/pull/26

https://github.com/KnapsackPro/knapsack_pro-ruby/compare/v0.1.0...v0.1.1

### 0.1.0

First working release on rubygems.org.

### 0.0.1

Init repository.
