### 2.10.0 / 2022-02-17

* Feature
  * Adds :order option to compare, with new `:baseline` order which compares all
    variations against the first option benchmarked.

### 2.9.3 / 2022-01-25

* Bug fix
  * All warmups and benchmarks must run at least once

### 2.9.2 / 2021-10-10

* Bug fix
  * Fix a problem with certain configs of quiet mode

### 2.9.1 / 2021-05-24

* Bug fix
  * Include all files in gem

### 2.9.0 / 2021-05-21

* Features
  * Suite can now be set via an accessor
  * Default SHARE_URL is now `ips.fastruby.io`, operated by Ombu Labs.

### 2.8.4 / 2020-12-03

* Bug fix
  * Fixed hold! when results file does not exist.

### 2.8.3 / 2020-08-28

* Bug fix
  * Fixed inaccuracy caused by integer overflows.

### 2.8.2 / 2020-05-04

* Bug fix
  * Fixed problems with Manifest.txt.
  * Empty interim results files are ignored.

### 2.8.0 / 2020-05-01

* Feature
  * Allow running with empty ips block.
  * Added save! method for saving interim results.
  * Run more than just 1 cycle during warmup to reduce overhead.
  * Optimized Job::Entry hot-path for fairer results on JRuby/TruffleRuby.

* Bug fix
  * Removed the warmup section if set to 0.
  * Added some RDoc docs.
  * Added some examples in examples/

### 2.7.2 / 2016-08-18

* 1 bug fix:
  * Restore old accessors. Fixes #76

### 2.7.1 / 2016-08-08

Add missing files

### 2.7.0 / 2016-08-05

* 1 minor features:
  * Add support for confidence intervals

* 1 bug fixes:
  * Cleanup a few coding patterns

* 2 doc fixes:
  * Add infos about benchark.fyi to Readme
  * Remove ancient releases

* 3 merged PRs:
  * Merge pull request #65 from kbrock/fixup_inject
  * Merge pull request #67 from benoittgt/master
  * Merge pull request #69 from chrisseaton/kalibera-confidence-intervals

### MISSING 2.6.0 and 2.6.1

### 2.5.0 / 2016-02-14

* 1 minor feature:
  * Add iterations option.

* 1 bug fixes:
  * Don't tell people something is slower if it's within the error.

* 2 merged PRs:
  * Merge pull request #58 from chrisseaton/iterations
  * Merge pull request #60 from chrisseaton/significance

### 2.4.1 / 2016-02-12

* 1 bug fix:
  * Add missing files to gem

### 2.4.0 / 2016-02-12

* 1 minor features
  * Add support for hold! and independent invocations.

* 6 bug fixes
  * Separate messages for warming up and calculating.
  * Tighten timing loop.
  * Pass simple types into Job#create_report
  * More concise sorting
  * Fix runtime comparison
  * Use runtime if ips is not available

* 5 doc fixes
  * Fix typo unsed --> used
  * Better document Report::Entry
  * Fix some typos in docs
  * Don't calculate mean 2 times
  * Add more tolerance to tests

* 13 merged PRs
  * Merge pull request #44 from kbrock/job_extract
  * Merge pull request #45 from kbrock/runtime_only
  * Merge pull request #47 from kbrock/use_avg
  * Merge pull request #46 from kbrock/report_stdout
  * Merge pull request #48 from bquorning/fix-label-for-runtime-comparison
  * Merge pull request #50 from tjschuck/fix_typo
  * Merge pull request #51 from bquorning/all-reports-respond-to-ips
  * Merge pull request #52 from kbrock/document_reports
  * Merge pull request #53 from kbrock/interface_create_report
  * Merge pull request #54 from PragTob/patch-2
  * Merge pull request #55 from chrisseaton/messages
  * Merge pull request #56 from chrisseaton/independence
  * Merge pull request #57 from chrisseaton/tighten-loop

### 2.3.0 / 2015-07-20

* 2 minor features:
  * Support keyword arguments
  * Allow any datatype for labels (use #to_s conversion)

* 1 doc/test changes:
  * Newer Travis for 1.8.7, ree, and 2.2.2

* 3 PRs merged:
  * Merge pull request #41 from kbrock/kwargs-support
  * Merge pull request #42 from kbrock/newer_travis
  * Merge pull request #43 from kbrock/non_to_s_labels

### 2.2.0 / 2015-05-09

* 1 minor features:
  * Fix quiet mode
  * Allow passing a custom suite via config
  * Silent a job if a suite was passed and is quiet
  * Export report to json file.
  * Accept symbol as report's argument.

* 2 doc fixes:
  * Squish duplicate `to` in README
  * Update copyright to 2015. [ci skip]

* 9 PRs merged:
  * Merge pull request #37 from splattael/patch-1
  * Merge pull request #36 from kirs/quiet-mode
  * Merge pull request #35 from JuanitoFatas/doc/suite
  * Merge pull request #34 from splattael/config-suite
  * Merge pull request #33 from splattael/suite-quiet
  * Merge pull request #32 from O-I/remove-gemfile-lock
  * Merge pull request #31 from JuanitoFatas/doc/bump-copyright-year
  * Merge pull request #29 from JuanitoFatas/feature/json-export
  * Merge pull request #26 from JuanitoFatas/feature/takes-symbol-as-report-parameter

### 2.1.1 / 2015-01-12

* 1 minor fix:
  * Don't send label through printf so that % work directly

* 1 documenation changes:
  * Use HEREDOC and wrap at 80 chars for example result description

* 1 usage fix:
  * Add gemspec for use via bundler git

* 1 PR merged:
  * Merge pull request #24 from zzak/simple-format-result-description

### 2.1.0 / 2014-11-10

* Documentation changes:
  * Many documentation fixes by Juanito Fatas!
  * Minor readme fix by Will Leinweber

* 2 minor features:
  * Displaying the total runtime for a job is suppressed unless interesting
  * Formatting of large values improved (human vs raw mode)
    * Contributed by Charles Oliver Nutter

### 2.0.0 / 2014-06-18

* The 'Davy Stevenson' release!
  * Codename: Springtime Hummingbird Dance

 * Big API refactoring so the internal bits are easier to use
 * Bump to 2.0 because return types changed to make the API better

* Contributors added:
  *  Davy Stevenson
  *  Juanito Fatas
  *  Benoit Daloze
  *  Matias
  *  Tony Arcieri
  *  Vipul A M
  *  Zachary Scott
  *  schneems (Richard Schneeman)

### 1.0.0 / 2012-03-23

* 1 major enhancement

  * Birthday!

