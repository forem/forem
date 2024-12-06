# Changelog

## [Unreleased](https://github.com/mhenrixon/sidekiq-unique-jobs/tree/HEAD)

[Full Changelog](https://github.com/mhenrixon/sidekiq-unique-jobs/compare/v7.1.28...HEAD)

**Fixed bugs:**

- fix\(digests\): ensure consistent digests [\#743](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/743) ([mhenrixon](https://github.com/mhenrixon))

**Merged pull requests:**

- fix\(after\_unlock\): regression from \#707 [\#737](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/737) ([adamcreekroad](https://github.com/adamcreekroad))

## [v7.1.28](https://github.com/mhenrixon/sidekiq-unique-jobs/tree/v7.1.28) (2022-11-28)

[Full Changelog](https://github.com/mhenrixon/sidekiq-unique-jobs/compare/v7.1.27...v7.1.28)

**Fixed bugs:**

- Unique Jobs Not Running with Version 7.1.26  [\#730](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/730)

**Closed issues:**

- Error "undefined method `redis\_info' for Sidekiq:Module" on upgrade  [\#740](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/740)
- spammed by `Nothing to delete; exiting` during spec [\#733](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/733)

**Merged pull requests:**

- sentence correction [\#744](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/744) ([SupriyaMedankar](https://github.com/SupriyaMedankar))

## [v7.1.27](https://github.com/mhenrixon/sidekiq-unique-jobs/tree/v7.1.27) (2022-07-30)

[Full Changelog](https://github.com/mhenrixon/sidekiq-unique-jobs/compare/v7.1.26...v7.1.27)

**Implemented enhancements:**

- Feat\(logging\): Allow disabling logging [\#729](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/729) ([mhenrixon](https://github.com/mhenrixon))

**Fixed bugs:**

- Fix\(namespace\): Prevent self-conflict when redis-namespace is present [\#732](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/732) ([mhenrixon](https://github.com/mhenrixon))

**Closed issues:**

- Disable logging in Rails testing [\#727](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/727)
- Memory bloat / dangling keys / reaper not cleaning orphans [\#637](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/637)

## [v7.1.26](https://github.com/mhenrixon/sidekiq-unique-jobs/tree/v7.1.26) (2022-07-28)

[Full Changelog](https://github.com/mhenrixon/sidekiq-unique-jobs/compare/v7.1.25...v7.1.26)

**Implemented enhancements:**

- Fix\(until\_expired\): Fix test and implementation [\#725](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/725) ([mhenrixon](https://github.com/mhenrixon))

**Fixed bugs:**

- Fix\(until\_and\_while\_executing\): Improve timeouts slightly [\#728](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/728) ([mhenrixon](https://github.com/mhenrixon))
- Fix\(unlock\): Delete primed keys on last entry [\#726](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/726) ([mhenrixon](https://github.com/mhenrixon))

**Merged pull requests:**

- Ensure batch delete removes expiring locks [\#724](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/724) ([francesmcmullin](https://github.com/francesmcmullin))
- Chore: Update dependencies [\#722](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/722) ([mhenrixon](https://github.com/mhenrixon))
- Move until\_expired digests to separate zset [\#721](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/721) ([francesmcmullin](https://github.com/francesmcmullin))
- Avoid skipping ranges when looping through queues [\#720](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/720) ([francesmcmullin](https://github.com/francesmcmullin))
- Bump actions/checkout from 2 to 3 [\#718](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/718) ([dependabot[bot]](https://github.com/apps/dependabot))
- Add Dependabot for GitHub Actions [\#717](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/717) ([petergoldstein](https://github.com/petergoldstein))
- Fix Sidekiq::Worker.clear\_all override not being applied [\#714](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/714) ([dsander](https://github.com/dsander))

## [v7.1.25](https://github.com/mhenrixon/sidekiq-unique-jobs/tree/v7.1.25) (2022-06-13)

[Full Changelog](https://github.com/mhenrixon/sidekiq-unique-jobs/compare/v7.1.24...v7.1.25)

**Fixed bugs:**

- Fix: Include the correct middleware [\#716](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/716) ([mhenrixon](https://github.com/mhenrixon))

## [v7.1.24](https://github.com/mhenrixon/sidekiq-unique-jobs/tree/v7.1.24) (2022-06-09)

[Full Changelog](https://github.com/mhenrixon/sidekiq-unique-jobs/compare/v7.1.23...v7.1.24)

**Implemented enhancements:**

- Chore: Sidekiq 6.5 compatibility [\#715](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/715) ([mhenrixon](https://github.com/mhenrixon))

**Merged pull requests:**

- Use sidekiq/testing `Worker.clear` API in sidekiq\_unique\_jobs/testing [\#713](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/713) ([dsander](https://github.com/dsander))

## [v7.1.23](https://github.com/mhenrixon/sidekiq-unique-jobs/tree/v7.1.23) (2022-05-23)

[Full Changelog](https://github.com/mhenrixon/sidekiq-unique-jobs/compare/v7.1.22...v7.1.23)

**Fixed bugs:**

- fix: raise on error [\#712](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/712) ([mhenrixon](https://github.com/mhenrixon))

## [v7.1.22](https://github.com/mhenrixon/sidekiq-unique-jobs/tree/v7.1.22) (2022-05-04)

[Full Changelog](https://github.com/mhenrixon/sidekiq-unique-jobs/compare/v7.1.21...v7.1.22)

**Fixed bugs:**

- Failed jobs waiting to be retried are not considered when fetching uniqueness [\#394](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/394)
- fix\(locksmith\): execute to yield without arguments [\#710](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/710) ([mhenrixon](https://github.com/mhenrixon))
- fix: re:lock until\_executing on worker failure [\#709](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/709) ([mhenrixon](https://github.com/mhenrixon))

**Closed issues:**

- Reviwing: Failed jobs waiting to be retried are not considered when fetching uniqueness [\#708](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/708)

## [v7.1.21](https://github.com/mhenrixon/sidekiq-unique-jobs/tree/v7.1.21) (2022-04-23)

[Full Changelog](https://github.com/mhenrixon/sidekiq-unique-jobs/compare/v7.1.20...v7.1.21)

**Implemented enhancements:**

- Prepare for Sidekiq v7 [\#707](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/707) ([mhenrixon](https://github.com/mhenrixon))

**Closed issues:**

- DEPRECATION WARNING: default\_worker\_options is deprecated and will be removed from Sidekiq 7.0 \(use default\_job\_options instead\) \(called from notify\_agents at /Users/hackeron/Development/Tether/timeline/app/models/user.rb:303\) [\#705](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/705)

## [v7.1.20](https://github.com/mhenrixon/sidekiq-unique-jobs/tree/v7.1.20) (2022-04-22)

[Full Changelog](https://github.com/mhenrixon/sidekiq-unique-jobs/compare/v7.1.19...v7.1.20)

**Implemented enhancements:**

- Manually handle timeouts [\#706](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/706) ([mhenrixon](https://github.com/mhenrixon))

**Merged pull requests:**

- improve README wrt. middleware config [\#704](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/704) ([slhck](https://github.com/slhck))

## [v7.1.19](https://github.com/mhenrixon/sidekiq-unique-jobs/tree/v7.1.19) (2022-04-09)

[Full Changelog](https://github.com/mhenrixon/sidekiq-unique-jobs/compare/v7.1.18...v7.1.19)

**Fixed bugs:**

- concurrent-ruby 1.1.10 spikes volume of jobs [\#701](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/701)
- Reimplement the entire TimerTask as it was [\#702](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/702) ([mhenrixon](https://github.com/mhenrixon))

## [v7.1.18](https://github.com/mhenrixon/sidekiq-unique-jobs/tree/v7.1.18) (2022-04-05)

[Full Changelog](https://github.com/mhenrixon/sidekiq-unique-jobs/compare/v7.1.17...v7.1.18)

**Implemented enhancements:**

- Make sure we reflect on execution failure [\#700](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/700) ([mhenrixon](https://github.com/mhenrixon))

## [v7.1.17](https://github.com/mhenrixon/sidekiq-unique-jobs/tree/v7.1.17) (2022-04-05)

[Full Changelog](https://github.com/mhenrixon/sidekiq-unique-jobs/compare/v7.1.16...v7.1.17)

## [v7.1.16](https://github.com/mhenrixon/sidekiq-unique-jobs/tree/v7.1.16) (2022-04-02)

[Full Changelog](https://github.com/mhenrixon/sidekiq-unique-jobs/compare/v7.1.15...v7.1.16)

**Implemented enhancements:**

- Abort Ruby Reaper when sidekiq queues are full [\#690](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/690) ([francesmcmullin](https://github.com/francesmcmullin))
- Quote '3.0' to ensure CI uses Ruby 3.0.x for the 3.0 entry [\#689](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/689) ([petergoldstein](https://github.com/petergoldstein))

**Fixed bugs:**

- Hotfix: Ensure consistent lock args [\#699](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/699) ([mhenrixon](https://github.com/mhenrixon))
- Expire older changelog entries first [\#698](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/698) ([mhenrixon](https://github.com/mhenrixon))
- Fix drift [\#688](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/688) ([mhenrixon](https://github.com/mhenrixon))

**Closed issues:**

- concurrent-ruby has dropped support for TimerTask timeouts [\#697](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/697)
- Most recent changelogs are removed first [\#696](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/696)
- Improve README slightly [\#694](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/694)
- locksmith.rb:327: NoMethodError:  undefined method `+' for nil:NilClass [\#686](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/686)
- lock\_timeout cannot be nil [\#675](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/675)
- Skip reaping when queues are too large [\#670](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/670)

**Merged pull requests:**

- Improve readme [\#695](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/695) ([fwolfst](https://github.com/fwolfst))
- Add funding\_uri to gemspec [\#693](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/693) ([fwolfst](https://github.com/fwolfst))
- Fix worker validator [\#685](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/685) ([victorfgs](https://github.com/victorfgs))

## [v7.1.15](https://github.com/mhenrixon/sidekiq-unique-jobs/tree/v7.1.15) (2022-02-10)

[Full Changelog](https://github.com/mhenrixon/sidekiq-unique-jobs/compare/v7.1.14...v7.1.15)

**Merged pull requests:**

- Fixing reschedule when using a non default queue [\#679](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/679) ([bigzed](https://github.com/bigzed))

## [v7.1.14](https://github.com/mhenrixon/sidekiq-unique-jobs/tree/v7.1.14) (2022-02-04)

[Full Changelog](https://github.com/mhenrixon/sidekiq-unique-jobs/compare/v7.1.13...v7.1.14)

**Implemented enhancements:**

- Fix the remaining deprecation warnings [\#681](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/681) ([mhenrixon](https://github.com/mhenrixon))

## [v7.1.13](https://github.com/mhenrixon/sidekiq-unique-jobs/tree/v7.1.13) (2022-02-03)

[Full Changelog](https://github.com/mhenrixon/sidekiq-unique-jobs/compare/v7.1.12...v7.1.13)

**Implemented enhancements:**

- Prepare for redis 5.0.0 [\#680](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/680) ([mhenrixon](https://github.com/mhenrixon))

**Fixed bugs:**

- Fix homepage url [\#667](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/667) ([dal-ioki](https://github.com/dal-ioki))

**Closed issues:**

- Job finished, but lock is not cleared [\#677](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/677)
- sidekiq\_options lock conflicts with sidekiq-lock gem lock option [\#669](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/669)
- Slow evalsha causing timeouts [\#668](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/668)
- Inconsistent documentation for config validation [\#647](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/647)

**Merged pull requests:**

- Bump bundler and friends [\#674](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/674) ([mhenrixon](https://github.com/mhenrixon))
- readme: fix minitest assertion. [\#672](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/672) ([crondaemon](https://github.com/crondaemon))
- Pass `item` in `after_unlock` callback [\#665](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/665) ([piloos](https://github.com/piloos))

## [v7.1.12](https://github.com/mhenrixon/sidekiq-unique-jobs/tree/v7.1.12) (2021-12-01)

[Full Changelog](https://github.com/mhenrixon/sidekiq-unique-jobs/compare/v7.1.11...v7.1.12)

**Implemented enhancements:**

- Improve Ruby Reaper performance under heavy load [\#663](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/663)
- Improve reaper performance under heavy load [\#666](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/666) ([mhenrixon](https://github.com/mhenrixon))

## [v7.1.11](https://github.com/mhenrixon/sidekiq-unique-jobs/tree/v7.1.11) (2021-11-30)

[Full Changelog](https://github.com/mhenrixon/sidekiq-unique-jobs/compare/v7.1.10...v7.1.11)

**Fixed bugs:**

- Fix ruby reaper edge case [\#661](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/661) ([mhenrixon](https://github.com/mhenrixon))

**Closed issues:**

- Question: Wait instead of cancelling if it is executing? [\#655](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/655)
- Expired Locks remain in zset of digests \[using "until\_expired" lock\] [\#653](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/653)
- \[Q&A\] Performance & Dead Locks [\#652](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/652)
- Sidekiq 6.3.0 includes Job module that clashes with sidekiq\_unique\_ext.rb class Job [\#651](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/651)

## [v7.1.10](https://github.com/mhenrixon/sidekiq-unique-jobs/tree/v7.1.10) (2021-10-18)

[Full Changelog](https://github.com/mhenrixon/sidekiq-unique-jobs/compare/v7.1.8...v7.1.10)

**Fixed bugs:**

- "IndexError: string not matched" when job is replaced on client [\#635](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/635)

**Merged pull requests:**

- Update URL for Sidekiq's Enterprise unique jobs [\#648](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/648) ([jsantos](https://github.com/jsantos))

## [v7.1.8](https://github.com/mhenrixon/sidekiq-unique-jobs/tree/v7.1.8) (2021-10-08)

[Full Changelog](https://github.com/mhenrixon/sidekiq-unique-jobs/compare/v7.0.13...v7.1.8)

**Fixed bugs:**

- undefined method `delete' for class `Sidekiq::Job' [\#634](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/634)
- INFO keys not persisted when job is enqueued [\#602](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/602)
- lock\_info set to true but no lock info showing up in web ui [\#589](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/589)
- Prevent too eager cleanup of lock info [\#645](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/645) ([mhenrixon](https://github.com/mhenrixon))

**Closed issues:**

- Compatibility with unreleased Sidekiq 6.3.0 [\#636](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/636)

**Merged pull requests:**

- Update docs [\#644](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/644) ([andypple](https://github.com/andypple))

## [v7.0.13](https://github.com/mhenrixon/sidekiq-unique-jobs/tree/v7.0.13) (2021-09-27)

[Full Changelog](https://github.com/mhenrixon/sidekiq-unique-jobs/compare/v7.1.7...v7.0.13)

## [v7.1.7](https://github.com/mhenrixon/sidekiq-unique-jobs/tree/v7.1.7) (2021-09-27)

[Full Changelog](https://github.com/mhenrixon/sidekiq-unique-jobs/compare/v7.1.6...v7.1.7)

**Implemented enhancements:**

- Styles [\#642](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/642) ([mhenrixon](https://github.com/mhenrixon))

**Fixed bugs:**

- OnConflict::Replace: yield when lock was achieved [\#640](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/640) ([mhenrixon](https://github.com/mhenrixon))

## [v7.1.6](https://github.com/mhenrixon/sidekiq-unique-jobs/tree/v7.1.6) (2021-09-21)

[Full Changelog](https://github.com/mhenrixon/sidekiq-unique-jobs/compare/v7.1.5...v7.1.6)

**Closed issues:**

- until\_and\_while\_executing is not running the job at all in sidekiq-unique-jobs 7.1.4 [\#626](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/626)

**Merged pull requests:**

- Necessary upgrades for Sidekiq v6.2.2 [\#639](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/639) ([mhenrixon](https://github.com/mhenrixon))
- Tese to these in README.md [\#633](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/633) ([carrickr](https://github.com/carrickr))

## [v7.1.5](https://github.com/mhenrixon/sidekiq-unique-jobs/tree/v7.1.5) (2021-07-28)

[Full Changelog](https://github.com/mhenrixon/sidekiq-unique-jobs/compare/v7.1.4...v7.1.5)

**Fixed bugs:**

- Fix: UntilAndWhileExecuting [\#627](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/627) ([mhenrixon](https://github.com/mhenrixon))

## [v7.1.4](https://github.com/mhenrixon/sidekiq-unique-jobs/tree/v7.1.4) (2021-07-21)

[Full Changelog](https://github.com/mhenrixon/sidekiq-unique-jobs/compare/v7.1.3...v7.1.4)

**Fixed bugs:**

- Pass lock timeout to primed\_async [\#624](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/624) ([millerjs](https://github.com/millerjs))

## [v7.1.3](https://github.com/mhenrixon/sidekiq-unique-jobs/tree/v7.1.3) (2021-07-20)

[Full Changelog](https://github.com/mhenrixon/sidekiq-unique-jobs/compare/v7.1.2...v7.1.3)

**Fixed bugs:**

- Locks are not released: seeing 'Might need to be unlocked manually" warnings [\#594](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/594)
- Disable resurrector by default [\#623](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/623) ([mhenrixon](https://github.com/mhenrixon))
- Documentation fixes [\#622](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/622) ([ursm](https://github.com/ursm))

**Closed issues:**

- Lock until\_and\_while\_executing not working as expected [\#613](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/613)

**Merged pull requests:**

- Improve readme [\#621](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/621) ([mhenrixon](https://github.com/mhenrixon))

## [v7.1.2](https://github.com/mhenrixon/sidekiq-unique-jobs/tree/v7.1.2) (2021-07-01)

[Full Changelog](https://github.com/mhenrixon/sidekiq-unique-jobs/compare/v7.1.1...v7.1.2)

**Fixed bugs:**

- Ensure `limit` and `timeout` are always numbers [\#620](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/620) ([pinkahd](https://github.com/pinkahd))

## [v7.1.1](https://github.com/mhenrixon/sidekiq-unique-jobs/tree/v7.1.1) (2021-06-30)

[Full Changelog](https://github.com/mhenrixon/sidekiq-unique-jobs/compare/v7.1.0...v7.1.1)

**Fixed bugs:**

- Fix handling of lock timeout [\#619](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/619) ([mhenrixon](https://github.com/mhenrixon))

**Closed issues:**

- Max expiration for locks [\#593](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/593)

## [v7.1.0](https://github.com/mhenrixon/sidekiq-unique-jobs/tree/v7.1.0) (2021-06-29)

[Full Changelog](https://github.com/mhenrixon/sidekiq-unique-jobs/compare/v7.0.12...v7.1.0)

**Implemented enhancements:**

- Reflections [\#611](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/611) ([mhenrixon](https://github.com/mhenrixon))
- Start new orphan reaper process if orphan reaper is not running [\#604](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/604) ([AlexFlint73](https://github.com/AlexFlint73))

**Fixed bugs:**

- Fix numerous small issues with locking [\#616](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/616) ([mhenrixon](https://github.com/mhenrixon))
- Allow locksmith delete to work with strings [\#615](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/615) ([pinkahd](https://github.com/pinkahd))

## [v7.0.12](https://github.com/mhenrixon/sidekiq-unique-jobs/tree/v7.0.12) (2021-06-04)

[Full Changelog](https://github.com/mhenrixon/sidekiq-unique-jobs/compare/v7.0.11...v7.0.12)

**Implemented enhancements:**

- Reduce noise of perfectly valid scenario [\#610](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/610) ([mhenrixon](https://github.com/mhenrixon))

**Merged pull requests:**

- Set correct namespace for custom strategy example [\#609](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/609) ([Wolfer](https://github.com/Wolfer))
- Clarify the documentation related to lock\_ttl [\#607](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/607) ([donaldpiret](https://github.com/donaldpiret))

## [v7.0.11](https://github.com/mhenrixon/sidekiq-unique-jobs/tree/v7.0.11) (2021-05-16)

[Full Changelog](https://github.com/mhenrixon/sidekiq-unique-jobs/compare/v7.0.10...v7.0.11)

**Fixed bugs:**

- Constants are not necessary when deleting locks [\#606](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/606) ([mhenrixon](https://github.com/mhenrixon))

**Closed issues:**

- Sidekiq Pro Sharded Web UI Error \> 7.0.8 [\#605](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/605)
- Timed out after 0s while waiting for primed token [\#601](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/601)

## [v7.0.10](https://github.com/mhenrixon/sidekiq-unique-jobs/tree/v7.0.10) (2021-05-10)

[Full Changelog](https://github.com/mhenrixon/sidekiq-unique-jobs/compare/v7.0.9...v7.0.10)

**Fixed bugs:**

- Add drift to original value [\#603](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/603) ([mhenrixon](https://github.com/mhenrixon))

**Closed issues:**

- Nested Sidekiq jobs are not kicked off with until\_and\_while\_executing [\#600](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/600)

## [v7.0.9](https://github.com/mhenrixon/sidekiq-unique-jobs/tree/v7.0.9) (2021-04-26)

[Full Changelog](https://github.com/mhenrixon/sidekiq-unique-jobs/compare/v7.0.8...v7.0.9)

**Fixed bugs:**

- Fix recording lock\_info [\#599](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/599) ([mhenrixon](https://github.com/mhenrixon))

## [v7.0.8](https://github.com/mhenrixon/sidekiq-unique-jobs/tree/v7.0.8) (2021-04-14)

[Full Changelog](https://github.com/mhenrixon/sidekiq-unique-jobs/compare/v7.0.7...v7.0.8)

**Implemented enhancements:**

- Lock performance [\#595](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/595) ([mhenrixon](https://github.com/mhenrixon))
- Allow and test ruby 3.0 [\#587](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/587) ([mhenrixon](https://github.com/mhenrixon))

**Closed issues:**

- Question: where do orphaned locks come from? [\#592](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/592)
- upgrade\_v6\_lock : ERR wrong number of arguments for 'hmset' command [\#591](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/591)

**Merged pull requests:**

- Fix uniqueness examples url in documentation [\#596](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/596) ([sampatbadhe](https://github.com/sampatbadhe))

## [v7.0.7](https://github.com/mhenrixon/sidekiq-unique-jobs/tree/v7.0.7) (2021-03-19)

[Full Changelog](https://github.com/mhenrixon/sidekiq-unique-jobs/compare/v7.0.6...v7.0.7)

**Fixed bugs:**

- Web filter param not working in pagination [\#584](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/584) ([mhenrixon](https://github.com/mhenrixon))

## [v7.0.6](https://github.com/mhenrixon/sidekiq-unique-jobs/tree/v7.0.6) (2021-03-19)

[Full Changelog](https://github.com/mhenrixon/sidekiq-unique-jobs/compare/v7.0.5...v7.0.6)

**Fixed bugs:**

- Deprecation warning for redis behaviour change in 5.0 [\#579](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/579)
- Consider a match only when both values present [\#586](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/586) ([mhenrixon](https://github.com/mhenrixon))

**Closed issues:**

- Reaper: undefined method `delete\_suffix' for nil:NilClass [\#585](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/585)

## [v7.0.5](https://github.com/mhenrixon/sidekiq-unique-jobs/tree/v7.0.5) (2021-03-18)

[Full Changelog](https://github.com/mhenrixon/sidekiq-unique-jobs/compare/v7.0.4...v7.0.5)

**Implemented enhancements:**

- Improve compatibility with redis-namespace [\#581](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/581) ([Wolfer](https://github.com/Wolfer))

**Fixed bugs:**

- RubyReaper treats runtime lock as orphan and delete it [\#580](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/580)
- Prefer conn.exists? when possible [\#583](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/583) ([mhenrixon](https://github.com/mhenrixon))
- Don't reap :RUN keys when active [\#582](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/582) ([mhenrixon](https://github.com/mhenrixon))

**Closed issues:**

- redis-namespace asks to use admistrative commands directly [\#578](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/578)

## [v7.0.4](https://github.com/mhenrixon/sidekiq-unique-jobs/tree/v7.0.4) (2021-02-17)

[Full Changelog](https://github.com/mhenrixon/sidekiq-unique-jobs/compare/v7.0.3...v7.0.4)

**Fixed bugs:**

- Fix uninitialized scheduled task [\#577](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/577) ([ArturT](https://github.com/ArturT))

## [v7.0.3](https://github.com/mhenrixon/sidekiq-unique-jobs/tree/v7.0.3) (2021-02-17)

[Full Changelog](https://github.com/mhenrixon/sidekiq-unique-jobs/compare/v7.0.2...v7.0.3)

**Fixed bugs:**

- Reduce reaper threads [\#576](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/576) ([mhenrixon](https://github.com/mhenrixon))

**Merged pull requests:**

- Fix typo in README.md \[ci skip\] [\#575](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/575) ([yujideveloper](https://github.com/yujideveloper))

## [v7.0.2](https://github.com/mhenrixon/sidekiq-unique-jobs/tree/v7.0.2) (2021-02-08)

[Full Changelog](https://github.com/mhenrixon/sidekiq-unique-jobs/compare/v7.0.1...v7.0.2)

**Fixed bugs:**

- Lock not getting properly cleared for some jobs [\#560](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/560)
- while\_executing + raise let non-unique jobs to be executed [\#534](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/534)
- delete\_by\_digest does not work with the msg\['unique\_digest'\] value available in sidekiq\_retries\_exhausted [\#532](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/532)
- Multiple jobs running at the same time [\#531](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/531)
- Unable to setup in standalone Ruby project [\#523](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/523)
- v7.0.0.beta15 Can't push new jobs to queue [\#501](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/501)
- Reaper doesn't work - lua or ruby [\#498](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/498)
- Tasks run once, and then there is no launch [\#464](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/464)
- Jobs executing and immediately returning [\#418](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/418)
- until\_and\_while\_executing + sidekiq retry mechanism [\#395](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/395)
- Fix that :PRIMED keys are seemingly not removed [\#574](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/574) ([mhenrixon](https://github.com/mhenrixon))

**Closed issues:**

- Just some clarification on the documentation. [\#530](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/530)
- Unique Digests dashboard not filtering the full set of results [\#529](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/529)
- after\_unlock isn't called unless it's a class method [\#526](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/526)
- The job gets JID and goes to dead right away [\#522](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/522)
- Able to assign customise Redis setup  [\#509](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/509)
- SidekiqUniqueJobs::UniqueArgs\#create\_digest is getting called twice [\#391](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/391)

**Merged pull requests:**

- Fix example url in documentation [\#572](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/572) ([yboulkaid](https://github.com/yboulkaid))

## [v7.0.1](https://github.com/mhenrixon/sidekiq-unique-jobs/tree/v7.0.1) (2021-01-22)

[Full Changelog](https://github.com/mhenrixon/sidekiq-unique-jobs/compare/v7.0.0...v7.0.1)

**Implemented enhancements:**

- Any way to manually clear/reset the changelog history? [\#568](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/568)
- Present the entire changelog in its own view [\#569](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/569) ([mhenrixon](https://github.com/mhenrixon))

**Fixed bugs:**

- Fix configuration [\#570](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/570) ([mhenrixon](https://github.com/mhenrixon))

**Closed issues:**

- undefined method 'delete\_by\_digest' for SidekiqUniqueJobs::Digests:Class  [\#567](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/567)
- Rejected jobs are still displayed as 'Queued' with gem 'sidekiq-status' on /sidekiq/statuses [\#564](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/564)

## [v7.0.0](https://github.com/mhenrixon/sidekiq-unique-jobs/tree/v7.0.0) (2021-01-20)

[Full Changelog](https://github.com/mhenrixon/sidekiq-unique-jobs/compare/v7.0.0.beta29...v7.0.0)

**Implemented enhancements:**

- Give user full control over adding middleware [\#566](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/566) ([mhenrixon](https://github.com/mhenrixon))
- Fix coverage reporting and add coverage [\#565](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/565) ([mhenrixon](https://github.com/mhenrixon))

**Fixed bugs:**

- Race condition in ruby reaper [\#559](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/559)
- Fix until and while executed and improve documentation [\#397](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/397)
- Fix race condition to avoid reaping active jobs [\#563](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/563) ([mhenrixon](https://github.com/mhenrixon))

**Closed issues:**

- Is it possible to have a :until\_executed lock with an expiration time? [\#524](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/524)

## [v7.0.0.beta29](https://github.com/mhenrixon/sidekiq-unique-jobs/tree/v7.0.0.beta29) (2021-01-16)

[Full Changelog](https://github.com/mhenrixon/sidekiq-unique-jobs/compare/v7.0.0.beta28...v7.0.0.beta29)

**Fixed bugs:**

- Ruby Reaper active check incorrect [\#557](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/557)
- Routes with authentication should work with web [\#562](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/562) ([mhenrixon](https://github.com/mhenrixon))

**Closed issues:**

- Can't add the lock tab o nthe website when there is authentication through devise [\#561](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/561)

## [v7.0.0.beta28](https://github.com/mhenrixon/sidekiq-unique-jobs/tree/v7.0.0.beta28) (2021-01-07)

[Full Changelog](https://github.com/mhenrixon/sidekiq-unique-jobs/compare/v7.0.0.beta27...v7.0.0.beta28)

**Fixed bugs:**

- lock\_args does not work when you define the lock\_args argument and default lock\_args function at the same time. [\#548](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/548)
- incorrect `:while_executing` behavior [\#432](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/432)
- Fix active check for the worker hash [\#558](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/558) ([mhenrixon](https://github.com/mhenrixon))
- Prefer lock\_prefix not unique\_prefix [\#554](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/554) ([mhenrixon](https://github.com/mhenrixon))
- Fix issue 432 [\#552](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/552) ([mhenrixon](https://github.com/mhenrixon))

## [v7.0.0.beta27](https://github.com/mhenrixon/sidekiq-unique-jobs/tree/v7.0.0.beta27) (2020-11-03)

[Full Changelog](https://github.com/mhenrixon/sidekiq-unique-jobs/compare/v7.0.0.beta26...v7.0.0.beta27)

**Implemented enhancements:**

- Adds coverage for regression purposes [\#550](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/550) ([mhenrixon](https://github.com/mhenrixon))

**Fixed bugs:**

- Rename lock\_args to lock\_args\_method [\#551](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/551) ([mhenrixon](https://github.com/mhenrixon))

**Closed issues:**

- Documentation incorrect for `delete_by_digest` [\#547](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/547)
- Locked jobs after kill -9 with while\_executing lock [\#546](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/546)

## [v7.0.0.beta26](https://github.com/mhenrixon/sidekiq-unique-jobs/tree/v7.0.0.beta26) (2020-10-28)

[Full Changelog](https://github.com/mhenrixon/sidekiq-unique-jobs/compare/v6.0.25...v7.0.0.beta26)

**Implemented enhancements:**

- How to disable Reaper [\#543](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/543)
- Allow disabling of reaper [\#544](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/544) ([mhenrixon](https://github.com/mhenrixon))

**Merged pull requests:**

- Update sidekiq-unique-jobs.gemspec [\#542](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/542) ([sergey-alekseev](https://github.com/sergey-alekseev))

## [v6.0.25](https://github.com/mhenrixon/sidekiq-unique-jobs/tree/v6.0.25) (2020-10-26)

[Full Changelog](https://github.com/mhenrixon/sidekiq-unique-jobs/compare/v7.0.0.beta25...v6.0.25)

## [v7.0.0.beta25](https://github.com/mhenrixon/sidekiq-unique-jobs/tree/v7.0.0.beta25) (2020-10-26)

[Full Changelog](https://github.com/mhenrixon/sidekiq-unique-jobs/compare/v7.0.0.beta24...v7.0.0.beta25)

**Implemented enhancements:**

- Bump rubocop [\#539](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/539) ([mhenrixon](https://github.com/mhenrixon))

**Fixed bugs:**

- Ruby reaper not working, active jobs queried incorrectly [\#537](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/537)
- Fix RubyReaper active? [\#538](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/538) ([tanner-rutgers](https://github.com/tanner-rutgers))

**Closed issues:**

- ConnectionPool::TimeoutError and :until\_executed [\#535](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/535)

**Merged pull requests:**

- Support apartment [\#540](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/540) ([mhenrixon](https://github.com/mhenrixon))

## [v7.0.0.beta24](https://github.com/mhenrixon/sidekiq-unique-jobs/tree/v7.0.0.beta24) (2020-09-27)

[Full Changelog](https://github.com/mhenrixon/sidekiq-unique-jobs/compare/v7.0.0.beta23...v7.0.0.beta24)

**Implemented enhancements:**

- Support both instance method and class method [\#527](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/527) ([mhenrixon](https://github.com/mhenrixon))

**Closed issues:**

- Leaked keys in version 5.0.10 [\#519](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/519)

## [v7.0.0.beta23](https://github.com/mhenrixon/sidekiq-unique-jobs/tree/v7.0.0.beta23) (2020-06-23)

[Full Changelog](https://github.com/mhenrixon/sidekiq-unique-jobs/compare/v6.0.23...v7.0.0.beta23)

**Fixed bugs:**

- Exit early when no results are returned from LRANGE given jobs might already processed [\#521](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/521) ([vipulnsward](https://github.com/vipulnsward))

## [v6.0.23](https://github.com/mhenrixon/sidekiq-unique-jobs/tree/v6.0.23) (2020-06-23)

[Full Changelog](https://github.com/mhenrixon/sidekiq-unique-jobs/compare/v7.0.0.beta22...v6.0.23)

**Fixed bugs:**

- Ruby reaper incorrectly checks active jobs — removes every active lock as result [\#517](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/517)

## [v7.0.0.beta22](https://github.com/mhenrixon/sidekiq-unique-jobs/tree/v7.0.0.beta22) (2020-06-12)

[Full Changelog](https://github.com/mhenrixon/sidekiq-unique-jobs/compare/v7.0.0.beta21...v7.0.0.beta22)

**Fixed bugs:**

- Infinite loop in ruby reaper [\#515](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/515)
- Prevent reaping of active jobs [\#518](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/518) ([mhenrixon](https://github.com/mhenrixon))

## [v7.0.0.beta21](https://github.com/mhenrixon/sidekiq-unique-jobs/tree/v7.0.0.beta21) (2020-06-12)

[Full Changelog](https://github.com/mhenrixon/sidekiq-unique-jobs/compare/v7.0.0.beta20...v7.0.0.beta21)

**Implemented enhancements:**

- Move gems to gemfile [\#513](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/513) ([mhenrixon](https://github.com/mhenrixon))
- Move dev-gems from gemspec to gemfile [\#512](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/512) ([mhenrixon](https://github.com/mhenrixon))

**Fixed bugs:**

- Prevent indefinitely looping entries [\#516](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/516) ([mhenrixon](https://github.com/mhenrixon))

**Closed issues:**

- Missing web interface [\#514](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/514)

## [v7.0.0.beta20](https://github.com/mhenrixon/sidekiq-unique-jobs/tree/v7.0.0.beta20) (2020-06-02)

[Full Changelog](https://github.com/mhenrixon/sidekiq-unique-jobs/compare/v7.0.0.beta19...v7.0.0.beta20)

**Fixed bugs:**

- Reaper can't be registered again if sidekiq gets killed by SIGKILL [\#490](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/490)

**Closed issues:**

- How do I turn this on for only one job class? [\#510](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/510)

## [v7.0.0.beta19](https://github.com/mhenrixon/sidekiq-unique-jobs/tree/v7.0.0.beta19) (2020-05-21)

[Full Changelog](https://github.com/mhenrixon/sidekiq-unique-jobs/compare/v7.0.0.beta18...v7.0.0.beta19)

**Fixed bugs:**

- Expire reaper when not checking in [\#508](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/508) ([mhenrixon](https://github.com/mhenrixon))

## [v7.0.0.beta18](https://github.com/mhenrixon/sidekiq-unique-jobs/tree/v7.0.0.beta18) (2020-05-21)

[Full Changelog](https://github.com/mhenrixon/sidekiq-unique-jobs/compare/v7.0.0.beta17...v7.0.0.beta18)

**Fixed bugs:**

- Stringify on\_conflict hash in Job prepare method [\#507](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/507) ([jasonbekolay](https://github.com/jasonbekolay))

## [v7.0.0.beta17](https://github.com/mhenrixon/sidekiq-unique-jobs/tree/v7.0.0.beta17) (2020-05-20)

[Full Changelog](https://github.com/mhenrixon/sidekiq-unique-jobs/compare/v7.0.0.beta16...v7.0.0.beta17)

**Implemented enhancements:**

- Try GitHub actions [\#505](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/505) ([mhenrixon](https://github.com/mhenrixon))

**Fixed bugs:**

- Deep stringify worker options to account for hash in on\_conflict [\#506](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/506) ([jasonbekolay](https://github.com/jasonbekolay))

## [v7.0.0.beta16](https://github.com/mhenrixon/sidekiq-unique-jobs/tree/v7.0.0.beta16) (2020-05-19)

[Full Changelog](https://github.com/mhenrixon/sidekiq-unique-jobs/compare/v6.0.22...v7.0.0.beta16)

**Fixed bugs:**

- Deprecate configuration options with `default_` [\#504](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/504) ([mhenrixon](https://github.com/mhenrixon))
- Fix access to both server and client conflict [\#503](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/503) ([mhenrixon](https://github.com/mhenrixon))

**Closed issues:**

- V7 Beta 15 `on_conflict:` with Hash does not work on server [\#499](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/499)

## [v6.0.22](https://github.com/mhenrixon/sidekiq-unique-jobs/tree/v6.0.22) (2020-04-13)

[Full Changelog](https://github.com/mhenrixon/sidekiq-unique-jobs/compare/v7.0.0.beta15...v6.0.22)

## [v7.0.0.beta15](https://github.com/mhenrixon/sidekiq-unique-jobs/tree/v7.0.0.beta15) (2020-04-10)

[Full Changelog](https://github.com/mhenrixon/sidekiq-unique-jobs/compare/v7.0.0.beta14...v7.0.0.beta15)

**Implemented enhancements:**

- Duplicated scripts [\#492](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/492)
- CI: Use jruby-9.2.11.1 [\#485](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/485) ([olleolleolle](https://github.com/olleolleolle))

**Fixed bugs:**

- V7 - `on_conflict:` no longer accepts a Hash [\#495](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/495)
- Brpoplpush::RedisScript::LuaError: WRONGTYPE Operation against a key holding the wrong kind of value [\#491](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/491)
- Lua script bug [\#489](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/489)
- Reaper will delete locks for running jobs [\#488](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/488)
- Fix access to hash members [\#496](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/496) ([mhenrixon](https://github.com/mhenrixon))
- Fix cursor assignment [\#494](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/494) ([mhenrixon](https://github.com/mhenrixon))
- Prevent reaping of active jobs [\#493](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/493) ([mhenrixon](https://github.com/mhenrixon))

## [v7.0.0.beta14](https://github.com/mhenrixon/sidekiq-unique-jobs/tree/v7.0.0.beta14) (2020-03-30)

[Full Changelog](https://github.com/mhenrixon/sidekiq-unique-jobs/compare/v6.0.21...v7.0.0.beta14)

**Fixed bugs:**

- Use thread-safe digest creation mechanism [\#483](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/483) ([zormandi](https://github.com/zormandi))

## [v6.0.21](https://github.com/mhenrixon/sidekiq-unique-jobs/tree/v6.0.21) (2020-03-30)

[Full Changelog](https://github.com/mhenrixon/sidekiq-unique-jobs/compare/v7.0.0.beta13...v6.0.21)

## [v7.0.0.beta13](https://github.com/mhenrixon/sidekiq-unique-jobs/tree/v7.0.0.beta13) (2020-03-26)

[Full Changelog](https://github.com/mhenrixon/sidekiq-unique-jobs/compare/v7.0.0.beta12...v7.0.0.beta13)

**Fixed bugs:**

- Remove digest deletion for concurrent locks [\#482](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/482) ([mhenrixon](https://github.com/mhenrixon))

## [v7.0.0.beta12](https://github.com/mhenrixon/sidekiq-unique-jobs/tree/v7.0.0.beta12) (2020-03-25)

[Full Changelog](https://github.com/mhenrixon/sidekiq-unique-jobs/compare/v6.0.20...v7.0.0.beta12)

**Fixed bugs:**

- until\_expired is not setting TTL [\#468](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/468)
- Fix bug where expiration wasn't set until unlock [\#481](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/481) ([mhenrixon](https://github.com/mhenrixon))

## [v6.0.20](https://github.com/mhenrixon/sidekiq-unique-jobs/tree/v6.0.20) (2020-03-22)

[Full Changelog](https://github.com/mhenrixon/sidekiq-unique-jobs/compare/v7.0.0.beta11...v6.0.20)

**Fixed bugs:**

- Deletion of digest doesn't work from admin UI [\#438](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/438)

**Closed issues:**

- Please keep some recent versions on rubygems.org [\#478](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/478)
- validate\_worker! throws error [\#466](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/466)

## [v7.0.0.beta11](https://github.com/mhenrixon/sidekiq-unique-jobs/tree/v7.0.0.beta11) (2020-03-21)

[Full Changelog](https://github.com/mhenrixon/sidekiq-unique-jobs/compare/v7.0.0.beta10...v7.0.0.beta11)

**Fixed bugs:**

- Only configure RSpec when constant is defined [\#477](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/477) ([mhenrixon](https://github.com/mhenrixon))

## [v7.0.0.beta10](https://github.com/mhenrixon/sidekiq-unique-jobs/tree/v7.0.0.beta10) (2020-03-21)

[Full Changelog](https://github.com/mhenrixon/sidekiq-unique-jobs/compare/v6.0.19...v7.0.0.beta10)

**Implemented enhancements:**

- Rename remaining unique\_\* keys to lock\_\* [\#475](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/475) ([mhenrixon](https://github.com/mhenrixon))
- Split calculator into two separate [\#474](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/474) ([mhenrixon](https://github.com/mhenrixon))
- Prepare for improving tests [\#473](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/473) ([mhenrixon](https://github.com/mhenrixon))
- Update gemspec: thor [\#465](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/465) ([masawo](https://github.com/masawo))

**Fixed bugs:**

- With v6.0.18, Sidekiq doesn't run at all [\#471](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/471)
- Fix errors\_as\_string on lock\_config.rb [\#469](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/469) ([donaldpiret](https://github.com/donaldpiret))

**Merged pull requests:**

- README: Use SVG badges ✨ [\#470](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/470) ([olleolleolle](https://github.com/olleolleolle))
- remove deprecated/broken OptionsWithFallback\#unique\_type [\#435](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/435) ([zvkemp](https://github.com/zvkemp))

## [v6.0.19](https://github.com/mhenrixon/sidekiq-unique-jobs/tree/v6.0.19) (2020-03-21)

[Full Changelog](https://github.com/mhenrixon/sidekiq-unique-jobs/compare/v7.0.0.beta9...v6.0.19)

## [v7.0.0.beta9](https://github.com/mhenrixon/sidekiq-unique-jobs/tree/v7.0.0.beta9) (2019-12-04)

[Full Changelog](https://github.com/mhenrixon/sidekiq-unique-jobs/compare/v7.0.0.beta8...v7.0.0.beta9)

**Implemented enhancements:**

- Keys without TTL [\#417](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/417)
- Various changes to test and verify reliability [\#463](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/463) ([mhenrixon](https://github.com/mhenrixon))

**Closed issues:**

- until\_and\_while\_executing with sidekiq pro `reliable_scheduler!` [\#411](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/411)

## [v7.0.0.beta8](https://github.com/mhenrixon/sidekiq-unique-jobs/tree/v7.0.0.beta8) (2019-11-28)

[Full Changelog](https://github.com/mhenrixon/sidekiq-unique-jobs/compare/v7.0.0.beta7...v7.0.0.beta8)

**Implemented enhancements:**

- Allow worker to configure client and server strategies separately [\#402](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/402)
- Separate client and server on\_conflict [\#462](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/462) ([mhenrixon](https://github.com/mhenrixon))

**Fixed bugs:**

- `while_executing` has problems at low concurrency [\#384](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/384)
- lock: :until\_and\_while\_executing not working for scheduled jobs [\#334](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/334)

**Closed issues:**

- Custom Locks with error [\#392](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/392)
- :until\_executed jobs get stuck every now and then [\#379](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/379)

## [v7.0.0.beta7](https://github.com/mhenrixon/sidekiq-unique-jobs/tree/v7.0.0.beta7) (2019-11-28)

[Full Changelog](https://github.com/mhenrixon/sidekiq-unique-jobs/compare/v7.0.0.beta6...v7.0.0.beta7)

**Fixed bugs:**

- A worker with "While Executing" lock and "Reschedule" strategy is rescheduled forever [\#457](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/457)
- Prevent callbacks from preventing locks [\#460](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/460) ([mhenrixon](https://github.com/mhenrixon))

## [v7.0.0.beta6](https://github.com/mhenrixon/sidekiq-unique-jobs/tree/v7.0.0.beta6) (2019-11-28)

[Full Changelog](https://github.com/mhenrixon/sidekiq-unique-jobs/compare/v6.0.18...v7.0.0.beta6)

**Implemented enhancements:**

- Clarify usage with global\_id and sidekiq-status [\#455](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/455) ([mhenrixon](https://github.com/mhenrixon))

**Merged pull requests:**

- Fix that Sidekiq now sends instance of worker [\#459](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/459) ([mhenrixon](https://github.com/mhenrixon))
- Fix typo in readme [\#456](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/456) ([sheerun](https://github.com/sheerun))

## [v6.0.18](https://github.com/mhenrixon/sidekiq-unique-jobs/tree/v6.0.18) (2019-11-28)

[Full Changelog](https://github.com/mhenrixon/sidekiq-unique-jobs/compare/v7.0.0.beta5...v6.0.18)

**Fixed bugs:**

- Jobs not pushed when using sidekiq-status [\#412](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/412)

**Closed issues:**

- Unique jobs only executed once when used with sidekiq-global\_id [\#235](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/235)

## [v7.0.0.beta5](https://github.com/mhenrixon/sidekiq-unique-jobs/tree/v7.0.0.beta5) (2019-11-26)

[Full Changelog](https://github.com/mhenrixon/sidekiq-unique-jobs/compare/v6.0.17...v7.0.0.beta5)

**Implemented enhancements:**

- Bump rails [\#450](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/450) ([mhenrixon](https://github.com/mhenrixon))
- Rename myapp [\#449](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/449) ([mhenrixon](https://github.com/mhenrixon))
- Just to keep track of this [\#445](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/445) ([mhenrixon](https://github.com/mhenrixon))

**Fixed bugs:**

- Prevent multiple reapers [\#453](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/453) ([mhenrixon](https://github.com/mhenrixon))
- Make deletion compatible with redis-namespace [\#452](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/452) ([mhenrixon](https://github.com/mhenrixon))
- Make sure server process stays locked [\#448](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/448) ([mhenrixon](https://github.com/mhenrixon))

**Merged pull requests:**

- Bump gems [\#446](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/446) ([mhenrixon](https://github.com/mhenrixon))

## [v6.0.17](https://github.com/mhenrixon/sidekiq-unique-jobs/tree/v6.0.17) (2019-11-26)

[Full Changelog](https://github.com/mhenrixon/sidekiq-unique-jobs/compare/v6.0.16...v6.0.17)

## [v6.0.16](https://github.com/mhenrixon/sidekiq-unique-jobs/tree/v6.0.16) (2019-11-25)

[Full Changelog](https://github.com/mhenrixon/sidekiq-unique-jobs/compare/v7.0.0.beta4...v6.0.16)

## [v7.0.0.beta4](https://github.com/mhenrixon/sidekiq-unique-jobs/tree/v7.0.0.beta4) (2019-11-25)

[Full Changelog](https://github.com/mhenrixon/sidekiq-unique-jobs/compare/v7.0.0.beta3...v7.0.0.beta4)

**Fixed bugs:**

- Fix ruby reaper [\#444](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/444) ([mhenrixon](https://github.com/mhenrixon))

## [v7.0.0.beta3](https://github.com/mhenrixon/sidekiq-unique-jobs/tree/v7.0.0.beta3) (2019-11-24)

[Full Changelog](https://github.com/mhenrixon/sidekiq-unique-jobs/compare/v7.0.0.beta2...v7.0.0.beta3)

**Implemented enhancements:**

- Brpoplpush redis script [\#434](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/434) ([mhenrixon](https://github.com/mhenrixon))
- Drop support for almost EOL ruby 2.4 [\#433](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/433) ([mhenrixon](https://github.com/mhenrixon))

**Fixed bugs:**

- Redis is busy running script and script never terminates [\#441](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/441)
- Make the ruby reaper plain ruby [\#443](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/443) ([mhenrixon](https://github.com/mhenrixon))

**Closed issues:**

- Some jobs seem to be treated as duplicate despite empty queue [\#440](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/440)

**Merged pull requests:**

- Fix typo and some formatting issues in README [\#442](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/442) ([ajkerr](https://github.com/ajkerr))

## [v7.0.0.beta2](https://github.com/mhenrixon/sidekiq-unique-jobs/tree/v7.0.0.beta2) (2019-10-08)

[Full Changelog](https://github.com/mhenrixon/sidekiq-unique-jobs/compare/v7.0.0.beta1...v7.0.0.beta2)

**Fixed bugs:**

- Pass redis\_version into scripts [\#431](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/431) ([mhenrixon](https://github.com/mhenrixon))

**Closed issues:**

- incorrect `:until_and_while_executing` behavior [\#424](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/424)

## [v7.0.0.beta1](https://github.com/mhenrixon/sidekiq-unique-jobs/tree/v7.0.0.beta1) (2019-10-07)

[Full Changelog](https://github.com/mhenrixon/sidekiq-unique-jobs/compare/v6.0.15...v7.0.0.beta1)

**Implemented enhancements:**

- Bump ruby versions in Travis CI [\#425](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/425) ([giraffate](https://github.com/giraffate))
- Allow lock info to be configured from worker [\#407](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/407) ([mhenrixon](https://github.com/mhenrixon))
- Validate worker configuration [\#406](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/406) ([mhenrixon](https://github.com/mhenrixon))
- Codeclimate configuration [\#405](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/405) ([mhenrixon](https://github.com/mhenrixon))
- Ensure uniquejobs namespace [\#400](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/400) ([mhenrixon](https://github.com/mhenrixon))
- Prepare for version 7 [\#387](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/387) ([mhenrixon](https://github.com/mhenrixon))
- Provide some configuration DSL for custom Strategies and Locks [\#383](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/383) ([mberlanda](https://github.com/mberlanda))

**Fixed bugs:**

- Allow Sidekiq::Context to be used for logging [\#429](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/429) ([mhenrixon](https://github.com/mhenrixon))
- Fix sidekiq develop [\#426](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/426) ([mhenrixon](https://github.com/mhenrixon))
- Reap as many orphans as advertised [\#403](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/403) ([mhenrixon](https://github.com/mhenrixon))
- Reaper should remove :INFO keys [\#399](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/399) ([mhenrixon](https://github.com/mhenrixon))

**Merged pull requests:**

- Fix filename [\#409](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/409) ([piton4eg](https://github.com/piton4eg))
- Adds some assets for documentation [\#404](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/404) ([mhenrixon](https://github.com/mhenrixon))
- fix: documentation link [\#390](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/390) ([shaojunda](https://github.com/shaojunda))
- Move workers in examples into spec/support/workers [\#386](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/386) ([mhenrixon](https://github.com/mhenrixon))
- Rename rails\_example to my\_app [\#385](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/385) ([mhenrixon](https://github.com/mhenrixon))

## [v6.0.15](https://github.com/mhenrixon/sidekiq-unique-jobs/tree/v6.0.15) (2019-10-05)

[Full Changelog](https://github.com/mhenrixon/sidekiq-unique-jobs/compare/v6.0.13...v6.0.15)

**Implemented enhancements:**

- Lock both worker and queue [\#274](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/274)

**Fixed bugs:**

- Duplicate job was pushed \( v6.0.13 \) [\#414](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/414)
- Constant SidekiqUniqueJobs::Web::Digests not found [\#396](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/396)

**Closed issues:**

- :until\_executing does not schedule job in Sidekiq 6.0.1 at all [\#427](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/427)
- Typo in documentation [\#423](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/423)
- Error in documentation [\#422](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/422)
- FIFO strategy [\#415](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/415)
- NoMethodError on setting global configurations [\#413](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/413)
- Syntax error on using the v6.0.13 [\#410](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/410)
- Add support for on\_conflict: :log for UntilExecuting lock [\#408](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/408)
- Allow sidekiq\_options to set lock\_info [\#401](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/401)
- Validate sidekiq\_options for each worker [\#398](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/398)
- Expiration for all locks [\#393](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/393)
- Fix your paypal link in README [\#389](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/389)

## [v6.0.13](https://github.com/mhenrixon/sidekiq-unique-jobs/tree/v6.0.13) (2019-04-14)

[Full Changelog](https://github.com/mhenrixon/sidekiq-unique-jobs/compare/v6.0.12...v6.0.13)

**Implemented enhancements:**

- Delete runtime locks on exception [\#382](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/382) ([mhenrixon](https://github.com/mhenrixon))

**Closed issues:**

- Unique args in combination with sidekiq cron contains `_aj_symbol_keys` [\#363](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/363)
- Low quality piece of shit [\#360](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/360)
- Passthrough has been deprecated and will be removed in redis-namespace 2.0 [\#338](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/338)

## [v6.0.12](https://github.com/mhenrixon/sidekiq-unique-jobs/tree/v6.0.12) (2019-02-28)

[Full Changelog](https://github.com/mhenrixon/sidekiq-unique-jobs/compare/v6.0.11...v6.0.12)

**Fixed bugs:**

- we are receiving SidekiqUniqueJobs::ScriptError "Problem compiling convert\_legacy\_lock" after upgrading from 5.0.10 -\> 6.0.11 [\#377](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/377)
- Fix converting legacy locks [\#378](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/378) ([mhenrixon](https://github.com/mhenrixon))

## [v6.0.11](https://github.com/mhenrixon/sidekiq-unique-jobs/tree/v6.0.11) (2019-02-24)

[Full Changelog](https://github.com/mhenrixon/sidekiq-unique-jobs/compare/v6.0.10...v6.0.11)

**Implemented enhancements:**

- Reduce leftover keys [\#374](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/374) ([mhenrixon](https://github.com/mhenrixon))
- Prepare for sidekiq 6 [\#373](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/373) ([mhenrixon](https://github.com/mhenrixon))

**Fixed bugs:**

- Prevent memory leaks \(many locks stay in memory\) [\#368](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/368)
- :until\_and\_while\_executing not processing queued jobs after executing [\#355](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/355)
- Version 6: lets you schedule job with missing arguments [\#351](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/351)
- Version 6 Ignores Jobs Enqueued in Version 5 [\#345](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/345)
- Job will not enqueue even with no existing match [\#342](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/342)
- Convert v5 locks when needed [\#375](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/375) ([mhenrixon](https://github.com/mhenrixon))

**Closed issues:**

- Infinite lock using until\_and\_while\_executing after sidekiq restart [\#361](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/361)
- getting a crash using lock\_expiration on v6.0.6 [\#350](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/350)
- Problem when job failed and is retrying [\#332](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/332)

**Merged pull requests:**

- Clarify lock expiration in readme [\#376](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/376) ([mhenrixon](https://github.com/mhenrixon))

## [v6.0.10](https://github.com/mhenrixon/sidekiq-unique-jobs/tree/v6.0.10) (2019-02-23)

[Full Changelog](https://github.com/mhenrixon/sidekiq-unique-jobs/compare/v6.0.9...v6.0.10)

**Implemented enhancements:**

- Log job silently complete [\#371](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/371) ([tadejm](https://github.com/tadejm))

**Closed issues:**

- Unsure of sane defaults [\#372](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/372)

## [v6.0.9](https://github.com/mhenrixon/sidekiq-unique-jobs/tree/v6.0.9) (2019-02-11)

[Full Changelog](https://github.com/mhenrixon/sidekiq-unique-jobs/compare/v6.0.8...v6.0.9)

**Implemented enhancements:**

- Delete all locks button [\#357](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/357)
- John denisov add delete all button to web [\#370](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/370) ([mhenrixon](https://github.com/mhenrixon))
- Various upgrades [\#366](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/366) ([mhenrixon](https://github.com/mhenrixon))

## [v6.0.8](https://github.com/mhenrixon/sidekiq-unique-jobs/tree/v6.0.8) (2019-01-10)

[Full Changelog](https://github.com/mhenrixon/sidekiq-unique-jobs/compare/v6.0.7...v6.0.8)

**Fixed bugs:**

- Close \#359 [\#364](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/364) ([mhenrixon](https://github.com/mhenrixon))

**Closed issues:**

- Automatic unlock of jobs [\#362](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/362)
- \(6.0.7\) `uniquejobs:{digest}:AVAILABLE` keys never expire [\#359](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/359)
- Strange behavior using strategy "reject" with "until\_executed" [\#358](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/358)
- Pinpointing issues with unique digests not being removed [\#353](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/353)

**Merged pull requests:**

- update changelog [\#356](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/356) ([camallen](https://github.com/camallen))

## [v6.0.7](https://github.com/mhenrixon/sidekiq-unique-jobs/tree/v6.0.7) (2018-11-29)

[Full Changelog](https://github.com/mhenrixon/sidekiq-unique-jobs/compare/v5.0.11...v6.0.7)

**Implemented enhancements:**

- More integration tests [\#329](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/329) ([mhenrixon](https://github.com/mhenrixon))

**Fixed bugs:**

- Version 5: Job ID Hash Entries Not Removed if Unique Key Expires [\#346](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/346)
- Move the lpush last [\#354](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/354) ([mhenrixon](https://github.com/mhenrixon))
- Convert expiration time to integer [\#330](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/330) ([dareddov](https://github.com/dareddov))

**Closed issues:**

- First job never unlocks the lock / Endless waiting [\#352](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/352)
- Version 5&6: uniqueness not respected for Job without params [\#349](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/349)

**Merged pull requests:**

- Do not build keys on lua scripts [\#348](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/348) ([pacoguzman](https://github.com/pacoguzman))
- fix CHANGELOG syntax [\#344](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/344) ([timoschilling](https://github.com/timoschilling))
- Define Config class inside SidekiqUniqueJobs module [\#343](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/343) ([Slike9](https://github.com/Slike9))
- fix readme testing section [\#333](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/333) ([edmartins](https://github.com/edmartins))
- Fix typo in documentation \[ci-skip\] [\#327](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/327) ([mhenrixon](https://github.com/mhenrixon))

## [v5.0.11](https://github.com/mhenrixon/sidekiq-unique-jobs/tree/v5.0.11) (2018-11-19)

[Full Changelog](https://github.com/mhenrixon/sidekiq-unique-jobs/compare/v6.0.6...v5.0.11)

**Closed issues:**

- concurrent-ruby 1.1.1 is causing this gem to break [\#340](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/340)
- lock remains after job not properly finish [\#339](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/339)
- Using a different Redis instance [\#337](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/337)
- Using :until\_and\_while\_executing not yielding expected results [\#336](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/336)
- "payload is not unique", but cannot find digest or scheduled job [\#335](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/335)
- Confused with UntilExecuted documenation [\#326](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/326)
- Job never requeued after raising unhandled error with until\_and\_while\_executing? [\#322](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/322)

## [v6.0.6](https://github.com/mhenrixon/sidekiq-unique-jobs/tree/v6.0.6) (2018-08-09)

[Full Changelog](https://github.com/mhenrixon/sidekiq-unique-jobs/compare/v6.0.5...v6.0.6)

**Implemented enhancements:**

- Adds coverage for job retries [\#321](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/321) ([mhenrixon](https://github.com/mhenrixon))
- Internal refactoring [\#318](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/318) ([mhenrixon](https://github.com/mhenrixon))

**Closed issues:**

- Unique UntilExecuted not working while the job is executing? [\#319](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/319)

## [v6.0.5](https://github.com/mhenrixon/sidekiq-unique-jobs/tree/v6.0.5) (2018-08-07)

[Full Changelog](https://github.com/mhenrixon/sidekiq-unique-jobs/compare/v6.0.4...v6.0.5)

**Fixed bugs:**

- Unlock instead of signal [\#317](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/317) ([mhenrixon](https://github.com/mhenrixon))

**Closed issues:**

- Why is lock\_timeout: nil VERY DANGEROUS? [\#313](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/313)

## [v6.0.4](https://github.com/mhenrixon/sidekiq-unique-jobs/tree/v6.0.4) (2018-08-02)

[Full Changelog](https://github.com/mhenrixon/sidekiq-unique-jobs/compare/v6.0.3...v6.0.4)

**Fixed bugs:**

- Fix the broken expiration [\#316](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/316) ([mhenrixon](https://github.com/mhenrixon))

**Closed issues:**

- Question about until\_timeout with 6.0.0 [\#303](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/303)

## [v6.0.3](https://github.com/mhenrixon/sidekiq-unique-jobs/tree/v6.0.3) (2018-08-02)

[Full Changelog](https://github.com/mhenrixon/sidekiq-unique-jobs/compare/v6.0.2...v6.0.3)

**Fixed bugs:**

- Enable replace strategy [\#315](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/315) ([mhenrixon](https://github.com/mhenrixon))

**Closed issues:**

- Sidekiq Web Pagination Broken [\#309](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/309)

**Merged pull requests:**

- Correct documentation typo \[ci skip\] [\#312](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/312) ([mhenrixon](https://github.com/mhenrixon))

## [v6.0.2](https://github.com/mhenrixon/sidekiq-unique-jobs/tree/v6.0.2) (2018-08-01)

[Full Changelog](https://github.com/mhenrixon/sidekiq-unique-jobs/compare/v6.0.1...v6.0.2)

**Fixed bugs:**

- Not unlocking automatically \(version 6.0.0rc5\) [\#293](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/293)
- Bug fixes [\#310](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/310) ([mhenrixon](https://github.com/mhenrixon))

## [v6.0.1](https://github.com/mhenrixon/sidekiq-unique-jobs/tree/v6.0.1) (2018-07-31)

[Full Changelog](https://github.com/mhenrixon/sidekiq-unique-jobs/compare/v6.0.0...v6.0.1)

**Fixed bugs:**

- :until\_executed is throwing errors and not requeuing the job. [\#256](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/256)
- Remove unused method [\#307](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/307) ([mhenrixon](https://github.com/mhenrixon))

**Closed issues:**

- ArgumentError: sidekiq\_unique\_jobs/web breaks sidekiq Retries page [\#306](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/306)
- If the job dies, it doesn't remove the lock [\#304](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/304)

**Merged pull requests:**

- Dead jobs [\#308](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/308) ([mhenrixon](https://github.com/mhenrixon))
- Fix require path for sidekiq\_unique\_jobs/web [\#305](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/305) ([soundasleep](https://github.com/soundasleep))

## [v6.0.0](https://github.com/mhenrixon/sidekiq-unique-jobs/tree/v6.0.0) (2018-07-27)

[Full Changelog](https://github.com/mhenrixon/sidekiq-unique-jobs/compare/v6.0.0.rc8...v6.0.0)

## [v6.0.0.rc8](https://github.com/mhenrixon/sidekiq-unique-jobs/tree/v6.0.0.rc8) (2018-07-24)

[Full Changelog](https://github.com/mhenrixon/sidekiq-unique-jobs/compare/v6.0.0.rc7...v6.0.0.rc8)

**Implemented enhancements:**

- Add RequeueWhileExecuting strategy [\#223](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/223)
- New feature: Replace original job if duplicate is added [\#177](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/177)
- Add a replace strategy for client locks [\#302](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/302) ([mhenrixon](https://github.com/mhenrixon))

**Merged pull requests:**

- Add more details about testing uniqueness [\#301](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/301) ([mhenrixon](https://github.com/mhenrixon))
- Update README.md [\#300](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/300) ([pirj](https://github.com/pirj))

## [v6.0.0.rc7](https://github.com/mhenrixon/sidekiq-unique-jobs/tree/v6.0.0.rc7) (2018-07-23)

[Full Changelog](https://github.com/mhenrixon/sidekiq-unique-jobs/compare/v6.0.0.rc6...v6.0.0.rc7)

**Implemented enhancements:**

- Sidekiq web [\#297](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/297) ([mhenrixon](https://github.com/mhenrixon))
- Document code [\#296](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/296) ([mhenrixon](https://github.com/mhenrixon))
- Rename to `unique:` to `lock:` [\#295](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/295) ([mhenrixon](https://github.com/mhenrixon))

**Closed issues:**

- Unique Job not work while play with crontab [\#294](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/294)
- Making the GEM compatible with Ruby \< 2.3 [\#291](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/291)

**Merged pull requests:**

- Adds changelog entry [\#299](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/299) ([mhenrixon](https://github.com/mhenrixon))
- Fix README [\#298](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/298) ([mhenrixon](https://github.com/mhenrixon))

## [v6.0.0.rc6](https://github.com/mhenrixon/sidekiq-unique-jobs/tree/v6.0.0.rc6) (2018-07-15)

[Full Changelog](https://github.com/mhenrixon/sidekiq-unique-jobs/compare/v6.0.0.rc5...v6.0.0.rc6)

**Fixed bugs:**

- Don't unlock when worker raises an error [\#290](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/290) ([mhenrixon](https://github.com/mhenrixon))

**Closed issues:**

- Locking with retries [\#289](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/289)

**Merged pull requests:**

- Readme [\#288](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/288) ([mhenrixon](https://github.com/mhenrixon))

## [v6.0.0.rc5](https://github.com/mhenrixon/sidekiq-unique-jobs/tree/v6.0.0.rc5) (2018-06-30)

[Full Changelog](https://github.com/mhenrixon/sidekiq-unique-jobs/compare/v6.0.0.rc4...v6.0.0.rc5)

**Fixed bugs:**

- bundle exec jobs console does not work [\#253](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/253)
- Rename command line binary [\#287](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/287) ([mhenrixon](https://github.com/mhenrixon))

## [v6.0.0.rc4](https://github.com/mhenrixon/sidekiq-unique-jobs/tree/v6.0.0.rc4) (2018-06-30)

[Full Changelog](https://github.com/mhenrixon/sidekiq-unique-jobs/compare/v6.0.0.rc3...v6.0.0.rc4)

**Implemented enhancements:**

- Prepare for v6 [\#286](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/286) ([mhenrixon](https://github.com/mhenrixon))
- Only unlock not delete [\#285](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/285) ([mhenrixon](https://github.com/mhenrixon))

## [v6.0.0.rc3](https://github.com/mhenrixon/sidekiq-unique-jobs/tree/v6.0.0.rc3) (2018-06-29)

[Full Changelog](https://github.com/mhenrixon/sidekiq-unique-jobs/compare/v6.0.0.rc2...v6.0.0.rc3)

**Fixed bugs:**

- Fix waiting for locks [\#284](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/284) ([mhenrixon](https://github.com/mhenrixon))

## [v6.0.0.rc2](https://github.com/mhenrixon/sidekiq-unique-jobs/tree/v6.0.0.rc2) (2018-06-26)

[Full Changelog](https://github.com/mhenrixon/sidekiq-unique-jobs/compare/v6.0.0.rc1...v6.0.0.rc2)

**Implemented enhancements:**

- Within tests: workers enqueued in the future don't clear their unique locks after being drained/executed [\#254](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/254)
- Unexpected behavior with until\_executed [\#250](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/250)

**Fixed bugs:**

- Unique job needs to be unlocked manually? [\#261](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/261)
- Duplicate jobs getting created [\#257](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/257)
- Multiple non-unique jobs with until\_executed? [\#255](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/255)
- :until\_executing not unlocking when starting to run [\#245](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/245)
- Drop jobs hash [\#282](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/282) ([mhenrixon](https://github.com/mhenrixon))

**Closed issues:**

- Difference between :until\_and\_while\_executing vs :until\_executed is not clear [\#249](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/249)
- Deprecated Documentation [\#246](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/246)
- Are we meant to manually expire the unique jobs hash? [\#234](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/234)
- How :until\_executing works ? Run job only once and discard new jobs while another job is executing [\#226](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/226)

**Merged pull requests:**

- Remove some misleading information [\#283](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/283) ([mhenrixon](https://github.com/mhenrixon))

## [v6.0.0.rc1](https://github.com/mhenrixon/sidekiq-unique-jobs/tree/v6.0.0.rc1) (2018-06-26)

[Full Changelog](https://github.com/mhenrixon/sidekiq-unique-jobs/compare/v6.0.0.beta2...v6.0.0.rc1)

**Implemented enhancements:**

- Legacy support [\#280](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/280)
- Adds legacy support [\#281](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/281) ([mhenrixon](https://github.com/mhenrixon))
- Adds guard-reek [\#279](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/279) ([mhenrixon](https://github.com/mhenrixon))
- Fix UntilExpired [\#278](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/278) ([mhenrixon](https://github.com/mhenrixon))

## [v6.0.0.beta2](https://github.com/mhenrixon/sidekiq-unique-jobs/tree/v6.0.0.beta2) (2018-06-25)

[Full Changelog](https://github.com/mhenrixon/sidekiq-unique-jobs/compare/v6.0.0.beta1...v6.0.0.beta2)

**Implemented enhancements:**

- Make locks more robust [\#277](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/277) ([mhenrixon](https://github.com/mhenrixon))
- Rename UntilTimeout -\> UntilExpired [\#276](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/276) ([mhenrixon](https://github.com/mhenrixon))

## [v6.0.0.beta1](https://github.com/mhenrixon/sidekiq-unique-jobs/tree/v6.0.0.beta1) (2018-06-22)

[Full Changelog](https://github.com/mhenrixon/sidekiq-unique-jobs/compare/v6.0.0.beta...v6.0.0.beta1)

**Implemented enhancements:**

- Code smells [\#275](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/275) ([mhenrixon](https://github.com/mhenrixon))
- Reject while scheduling [\#273](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/273) ([mhenrixon](https://github.com/mhenrixon))
- Improve testing [\#272](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/272) ([mhenrixon](https://github.com/mhenrixon))
- Until and while executing [\#271](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/271) ([mhenrixon](https://github.com/mhenrixon))
- Solidify master [\#270](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/270) ([mhenrixon](https://github.com/mhenrixon))
- Minor adjustments [\#268](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/268) ([mhenrixon](https://github.com/mhenrixon))
- Use ruby 2.5.1 [\#267](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/267) ([mhenrixon](https://github.com/mhenrixon))
- Add explicit concurrent-ruby dependency. [\#265](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/265) ([brettburley](https://github.com/brettburley))

**Fixed bugs:**

- Allow `jobs keys` to default to listing all keys [\#252](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/252) ([soundasleep](https://github.com/soundasleep))

**Merged pull requests:**

- Improve documentation [\#269](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/269) ([mhenrixon](https://github.com/mhenrixon))
- Remove unnecessary monkey patches for String [\#262](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/262) ([zormandi](https://github.com/zormandi))
- README \> While Executing: remove unnecessary word [\#260](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/260) ([TimCannady](https://github.com/TimCannady))
- Don't skip monkeypatches if ActiveSupport present [\#248](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/248) ([dleavitt](https://github.com/dleavitt))
- Better runtime locks [\#241](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/241) ([mhenrixon](https://github.com/mhenrixon))

## [v6.0.0.beta](https://github.com/mhenrixon/sidekiq-unique-jobs/tree/v6.0.0.beta) (2018-06-17)

[Full Changelog](https://github.com/mhenrixon/sidekiq-unique-jobs/compare/v5.0.10...v6.0.0.beta)

**Closed issues:**

- Incomplete sentence in README [\#264](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/264)
- ActiveJob and Sidekiq::Worker [\#259](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/259)
- ActiveJob and Sidekiq::Worker [\#258](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/258)
- Non-unique jobs can be added even when `sidekiq_options unique: :until_executed` [\#251](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/251)
- Trouble with "inline" mode [\#243](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/243)
- Sidekiq::Worker.set not working with sidekiq-unique-jobs [\#242](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/242)
- sidekiq-unique-job with ActiveJob [\#238](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/238)
- Deadlock using :while\_executing? [\#233](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/233)

## [v5.0.10](https://github.com/mhenrixon/sidekiq-unique-jobs/tree/v5.0.10) (2017-08-19)

[Full Changelog](https://github.com/mhenrixon/sidekiq-unique-jobs/compare/v5.0.9...v5.0.10)

**Closed issues:**

- Version v5.0.5 might have introduced a breaking change in while\_executing and was not documented [\#230](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/230)
- String arguments not seen as unique  [\#222](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/222)
- unique\_args method suppresses all `NameError` exceptions [\#219](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/219)

**Merged pull requests:**

- Various improvements [\#240](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/240) ([mhenrixon](https://github.com/mhenrixon))
- Fix: uninitialized constant CustomQueueJob on rspec [\#239](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/239) ([dalpo](https://github.com/dalpo))

## [v5.0.9](https://github.com/mhenrixon/sidekiq-unique-jobs/tree/v5.0.9) (2017-07-06)

[Full Changelog](https://github.com/mhenrixon/sidekiq-unique-jobs/compare/v5.0.8...v5.0.9)

**Closed issues:**

- The work of several unique sidekiq tasks within one queue [\#225](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/225)
- Missing documentation on activejob usage [\#221](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/221)

**Merged pull requests:**

- Your testing lib is broken and don't permit to test uniqueness of jobs [\#232](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/232) ([keysen](https://github.com/keysen))
- Use hscan for Util\#expire [\#229](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/229) ([dmkc](https://github.com/dmkc))
- Fixed documentation example about unique\_args [\#228](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/228) ([andresakata](https://github.com/andresakata))
- Fix filename [\#224](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/224) ([ikataitsev](https://github.com/ikataitsev))

## [v5.0.8](https://github.com/mhenrixon/sidekiq-unique-jobs/tree/v5.0.8) (2017-05-03)

[Full Changelog](https://github.com/mhenrixon/sidekiq-unique-jobs/compare/v5.0.7...v5.0.8)

**Closed issues:**

- Using JSON.parse in delete\_by\_value\_ext break compatiblity with other Sidekiq extensions [\#220](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/220)
- Is it possible to get the Job ID of original job? [\#217](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/217)

## [v5.0.7](https://github.com/mhenrixon/sidekiq-unique-jobs/tree/v5.0.7) (2017-04-26)

[Full Changelog](https://github.com/mhenrixon/sidekiq-unique-jobs/compare/v5.0.6...v5.0.7)

**Closed issues:**

- Can't delete Sidekiq::Job after 5.0.1 [\#218](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/218)
- Uniqueness across workers [\#210](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/210)

## [v5.0.6](https://github.com/mhenrixon/sidekiq-unique-jobs/tree/v5.0.6) (2017-04-23)

[Full Changelog](https://github.com/mhenrixon/sidekiq-unique-jobs/compare/v5.0.5...v5.0.6)

**Closed issues:**

- Different unique arguments depending on lock type [\#203](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/203)
- Strategy until\_and\_while\_executing not working properly [\#199](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/199)
- while\_executing working wrong [\#193](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/193)

## [v5.0.5](https://github.com/mhenrixon/sidekiq-unique-jobs/tree/v5.0.5) (2017-04-23)

[Full Changelog](https://github.com/mhenrixon/sidekiq-unique-jobs/compare/v5.0.4...v5.0.5)

**Merged pull requests:**

- Fixed typo on README.md [\#216](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/216) ([jsantos](https://github.com/jsantos))

## [v5.0.4](https://github.com/mhenrixon/sidekiq-unique-jobs/tree/v5.0.4) (2017-04-18)

[Full Changelog](https://github.com/mhenrixon/sidekiq-unique-jobs/compare/v5.0.3...v5.0.4)

## [v5.0.3](https://github.com/mhenrixon/sidekiq-unique-jobs/tree/v5.0.3) (2017-04-18)

[Full Changelog](https://github.com/mhenrixon/sidekiq-unique-jobs/compare/v5.0.2...v5.0.3)

## [v5.0.2](https://github.com/mhenrixon/sidekiq-unique-jobs/tree/v5.0.2) (2017-04-17)

[Full Changelog](https://github.com/mhenrixon/sidekiq-unique-jobs/compare/v5.0.1...v5.0.2)

**Closed issues:**

- Uniqueness should not survive Class.jobs.clear [\#214](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/214)
- when arguments are empty then unique\_args proc/method is not executed [\#201](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/201)

## [v5.0.1](https://github.com/mhenrixon/sidekiq-unique-jobs/tree/v5.0.1) (2017-04-16)

[Full Changelog](https://github.com/mhenrixon/sidekiq-unique-jobs/compare/v5.0.0...v5.0.1)

**Closed issues:**

- Removing "uniquejobs" hash? [\#213](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/213)
- deprecation warnings with redis-namespace 2.0 [\#212](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/212)
- Unclear docs / examples for unique\_args [\#211](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/211)
- Jobs Console fails to launch [\#208](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/208)
- Util.del Redis::CommandError: ERR syntax error [\#207](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/207)
- version 4.0.19 [\#206](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/206)
- Job.delete does not remove lock in all circumstances [\#205](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/205)
- disappearing jobs - known issue in conjunction with other extensions? [\#202](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/202)
- Broken pipe @ io\_write - \<STDERR\> on sidekiq unique jobs [\#198](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/198)
- Doesn't play well with redis-namespace [\#196](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/196)
- SidekiqUniqueJobs::ScriptError [\#192](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/192)

**Merged pull requests:**

- Add the possibility to clear the hash [\#215](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/215) ([mhenrixon](https://github.com/mhenrixon))

## [v5.0.0](https://github.com/mhenrixon/sidekiq-unique-jobs/tree/v5.0.0) (2017-04-08)

[Full Changelog](https://github.com/mhenrixon/sidekiq-unique-jobs/compare/v4.0.18...v5.0.0)

**Fixed bugs:**

- Can't enable testing with newer versions of sidekiq [\#175](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/175)
- strange behaviour [\#172](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/172)

**Closed issues:**

- Could not find a valid gem 'sidekiq-unique-jobs' \(= 3.0.15\) in any repository [\#197](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/197)
- `uniquejobs` hash doesn't get cleaned up [\#195](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/195)
- Code block under "Finer Control over Uniqueness" in your documentation might have the wrong option specified [\#191](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/191)
- not able to run test without live Redis [\#186](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/186)
- unique while not sucessfully completed? [\#185](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/185)
- Duplicate jobs when using :until\_and\_while\_executing [\#181](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/181)
- unique: :while\_executing doesn't remove lock when the Sidekiq node running the job shuts down and terminates the job prematurely [\#170](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/170)
- :while\_executing appears to be broken [\#159](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/159)
- Using ":until\_executing, :until\_executed, :until\_timeout, :until\_and\_while\_executing" all break Sidekiq::Testing [\#157](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/157)
- Way to remove lock in application code [\#147](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/147)

**Merged pull requests:**

- Increase sleep delay in WhileExecuting\#synchronize [\#204](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/204) ([dsander](https://github.com/dsander))
- Ensure job ID removed from uniquejobs hash [\#200](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/200) ([carlosmartinez](https://github.com/carlosmartinez))
- unique args need to be an array [\#194](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/194) ([pboling](https://github.com/pboling))

## [v4.0.18](https://github.com/mhenrixon/sidekiq-unique-jobs/tree/v4.0.18) (2016-07-24)

[Full Changelog](https://github.com/mhenrixon/sidekiq-unique-jobs/compare/v4.0.17...v4.0.18)

**Closed issues:**

- ArgumentError: wrong number of arguments \(given 1, expected 2\) [\#190](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/190)
- Should be note on document only works on production mode [\#189](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/189)
- SidekiqUniqueJobs::ScriptError: release\_lock.lua NOSCRIPT No matching script. [\#187](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/187)
- sidekiq-unique-jobs kills sidekiq in production [\#183](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/183)
- Parameters turn into String [\#182](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/182)
- You really helped me today [\#180](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/180)
- 4.0.17 config  [\#171](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/171)
- Problem with releasing uniquejobs locks after timeout expires [\#169](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/169)
- NOSCRIPT No matching script. Please use EVAL. [\#168](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/168)
- Broken compatibility with Sidekiq 3.4 [\#140](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/140)

**Merged pull requests:**

- missed space [\#188](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/188) ([TheBigSadowski](https://github.com/TheBigSadowski))
- Convert unless if to just 1 if [\#179](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/179) ([otzy007](https://github.com/otzy007))
- fix for \#168. Handle the NOSCRIPT by sending the script again [\#178](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/178) ([otzy007](https://github.com/otzy007))
- Fixed gitter badge link [\#176](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/176) ([andrew](https://github.com/andrew))

## [v4.0.17](https://github.com/mhenrixon/sidekiq-unique-jobs/tree/v4.0.17) (2016-03-02)

[Full Changelog](https://github.com/mhenrixon/sidekiq-unique-jobs/compare/v4.0.16...v4.0.17)

**Closed issues:**

- No place where I can say "Thank you" for all contributors [\#165](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/165)

## [v4.0.16](https://github.com/mhenrixon/sidekiq-unique-jobs/tree/v4.0.16) (2016-02-17)

[Full Changelog](https://github.com/mhenrixon/sidekiq-unique-jobs/compare/v4.0.15...v4.0.16)

**Merged pull requests:**

- Fix for sidekiq delete failing for version 3.4.x  [\#167](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/167) ([theprogrammerin](https://github.com/theprogrammerin))
- Run lock timeout configurable [\#164](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/164) ([Slania](https://github.com/Slania))

## [v4.0.15](https://github.com/mhenrixon/sidekiq-unique-jobs/tree/v4.0.15) (2016-02-16)

[Full Changelog](https://github.com/mhenrixon/sidekiq-unique-jobs/compare/v4.0.13...v4.0.15)

**Closed issues:**

- Until timeout question [\#163](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/163)
- Error when run rspec [\#162](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/162)
- Unique job keys never dissapear [\#161](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/161)
- Uniqueness breaks jobs [\#160](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/160)
- Too many open files [\#155](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/155)

**Merged pull requests:**

- Add a Gitter chat badge to README.md [\#166](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/166) ([gitter-badger](https://github.com/gitter-badger))
- Fix test overrides. [\#158](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/158) ([benseligman](https://github.com/benseligman))
- Remove wrong Server::Middleware\#worker\_class override [\#156](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/156) ([vkuznetsov](https://github.com/vkuznetsov))

## [v4.0.13](https://github.com/mhenrixon/sidekiq-unique-jobs/tree/v4.0.13) (2015-12-16)

[Full Changelog](https://github.com/mhenrixon/sidekiq-unique-jobs/compare/v4.0.12...v4.0.13)

**Closed issues:**

- Seeing this error with latest version 4.0.12 [\#154](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/154)
- Unique job showing weird behavior [\#153](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/153)

## [v4.0.12](https://github.com/mhenrixon/sidekiq-unique-jobs/tree/v4.0.12) (2015-12-15)

[Full Changelog](https://github.com/mhenrixon/sidekiq-unique-jobs/compare/v4.0.11...v4.0.12)

**Closed issues:**

- Can't schedule a job from another job [\#151](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/151)
- perform\_in not working in version 4.0.9 [\#150](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/150)
- `unique: until_and_while_executing` not working as expected [\#146](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/146)
- while\_executing still runs duplicate tasks [\#136](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/136)
- Version 4 Upgrade [\#133](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/133)

## [v4.0.11](https://github.com/mhenrixon/sidekiq-unique-jobs/tree/v4.0.11) (2015-12-12)

[Full Changelog](https://github.com/mhenrixon/sidekiq-unique-jobs/compare/v4.0.10...v4.0.11)

**Closed issues:**

- Release a new version for Ruby \< 2.1 compatability [\#152](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/152)

## [v4.0.10](https://github.com/mhenrixon/sidekiq-unique-jobs/tree/v4.0.10) (2015-12-12)

[Full Changelog](https://github.com/mhenrixon/sidekiq-unique-jobs/compare/v4.0.9...v4.0.10)

**Closed issues:**

- Until Executed is taking waiting for unique\_expiration [\#149](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/149)
- Until Executed vs Unique Until And While Executing is confusing in README [\#148](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/148)
- sidekiq-unique-jobs not enabled from sidekiq workers [\#131](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/131)

## [v4.0.9](https://github.com/mhenrixon/sidekiq-unique-jobs/tree/v4.0.9) (2015-11-14)

[Full Changelog](https://github.com/mhenrixon/sidekiq-unique-jobs/compare/v4.0.8...v4.0.9)

**Closed issues:**

- Error when using unique\_args in 4.0.8 [\#145](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/145)
- Ignore lock when jobs spawned from another sidekiq worker [\#142](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/142)
- Two Rails apps on the same server, but only one Sidekiq instances is working correctly [\#141](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/141)
- ActiveRecord::RecordNotDestroyed: Failed to destroy the record [\#139](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/139)

## [v4.0.8](https://github.com/mhenrixon/sidekiq-unique-jobs/tree/v4.0.8) (2015-10-31)

[Full Changelog](https://github.com/mhenrixon/sidekiq-unique-jobs/compare/v4.0.7...v4.0.8)

**Closed issues:**

- Jobs not getting queued in v4 [\#138](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/138)
- Unique args being considered? [\#137](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/137)
- No mention how to test in README [\#135](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/135)
- License Difference [\#132](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/132)

**Merged pull requests:**

- Calculate worker's unique args when a proc or a symbol is specified [\#143](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/143) ([zeqfreed](https://github.com/zeqfreed))
- Fix markdown link formatting [\#134](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/134) ([thbar](https://github.com/thbar))

## [v4.0.7](https://github.com/mhenrixon/sidekiq-unique-jobs/tree/v4.0.7) (2015-10-14)

[Full Changelog](https://github.com/mhenrixon/sidekiq-unique-jobs/compare/v4.0.6...v4.0.7)

**Closed issues:**

- docs clarification [\#130](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/130)
- 4.\* is hurting background job workers performance [\#127](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/127)

## [v4.0.6](https://github.com/mhenrixon/sidekiq-unique-jobs/tree/v4.0.6) (2015-10-14)

[Full Changelog](https://github.com/mhenrixon/sidekiq-unique-jobs/compare/v4.0.5...v4.0.6)

**Closed issues:**

- NameError: uninitialized constant SidekiqUniqueJobs::RunLockFailed [\#126](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/126)

## [v4.0.5](https://github.com/mhenrixon/sidekiq-unique-jobs/tree/v4.0.5) (2015-10-13)

[Full Changelog](https://github.com/mhenrixon/sidekiq-unique-jobs/compare/v4.0.4...v4.0.5)

**Closed issues:**

-  Rails + Sidekiq will go bezerk after sidekiq-unique-jobs testing check. [\#128](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/128)
-  NoMethodError: undefined method `to\_sym' for true:TrueClass [\#125](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/125)
- Redis::CommandError: ERR unknown command 'eval' [\#124](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/124)

**Merged pull requests:**

- Forces to look for testing namespace in Sidekiq and not his ancestors [\#129](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/129) ([antek-drzewiecki](https://github.com/antek-drzewiecki))
- Fix outdated phrasing and add test coverage to readme [\#123](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/123) ([albertyw](https://github.com/albertyw))

## [v4.0.4](https://github.com/mhenrixon/sidekiq-unique-jobs/tree/v4.0.4) (2015-10-09)

[Full Changelog](https://github.com/mhenrixon/sidekiq-unique-jobs/compare/v4.0.3...v4.0.4)

**Closed issues:**

- Active job with unique args doesn't work [\#120](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/120)
- 4.0.1 =\> job no longer unique [\#117](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/117)
- Update Changelog and Tags [\#115](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/115)

## [v4.0.3](https://github.com/mhenrixon/sidekiq-unique-jobs/tree/v4.0.3) (2015-10-08)

[Full Changelog](https://github.com/mhenrixon/sidekiq-unique-jobs/compare/v4.0.2...v4.0.3)

**Closed issues:**

- unique\_unlock\_order - never option [\#122](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/122)
- Run 1 job and queue 1 [\#121](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/121)
- unique\_lock vs unique\_locks typo [\#119](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/119)
- 4.0.2 commited but not released to rubygems? [\#118](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/118)

## [v4.0.2](https://github.com/mhenrixon/sidekiq-unique-jobs/tree/v4.0.2) (2015-10-06)

[Full Changelog](https://github.com/mhenrixon/sidekiq-unique-jobs/compare/4.0.1...v4.0.2)

## [4.0.1](https://github.com/mhenrixon/sidekiq-unique-jobs/tree/4.0.1) (2015-10-06)

[Full Changelog](https://github.com/mhenrixon/sidekiq-unique-jobs/compare/v4.0.0...4.0.1)

**Closed issues:**

- Don't work with perform\_in [\#114](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/114)
- 3.0.15 apparently breaks inline testing [\#113](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/113)
- sidekiq\_unique record in Redis is not cleaned when foreman process is killed [\#112](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/112)
- Can't ensure unique job simultaneously. [\#111](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/111)
- Job considered as duplicate after completion only in production [\#110](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/110)
- Gem requires Redis 2.6+? [\#109](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/109)
- unable to re-schedule job at specific time [\#108](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/108)
- Documentation Not Clear [\#78](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/78)
- Runtime uniqueness when using :before\_yield as unlock order [\#72](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/72)
- Using with sidekiq delayed extensions [\#45](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/45)

**Merged pull requests:**

- Clean up version 4 upgrade instructions [\#116](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/116) ([albertyw](https://github.com/albertyw))

## [v4.0.0](https://github.com/mhenrixon/sidekiq-unique-jobs/tree/v4.0.0) (2015-10-05)

[Full Changelog](https://github.com/mhenrixon/sidekiq-unique-jobs/compare/v3.0.11...v4.0.0)

**Implemented enhancements:**

- Duplicated Jobs With Nested Sidekiq Workers [\#10](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/10)

**Closed issues:**

- 3.0.14 Error: ERR wrong number of arguments for 'set' command \(Redis::CommandError\) [\#104](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/104)
- Testing [\#103](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/103)
- Active Job [\#102](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/102)
- Why is SidekiqUnique behaviour applied to regular Workers?  [\#100](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/100)
- Confusing behavior when trying to `[1,2,3].each { |n| SomeJob.perform_in(n.seconds.from_now, n) }` never running, logging as duplicate value [\#98](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/98)
- Scheduled jobs are not unlocked when deleted [\#97](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/97)
- Testing functions should be moved out of production code  [\#95](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/95)
- Jobs can unlock mutexes they don't own  [\#94](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/94)
- Jobs scheduled in the future are never run [\#93](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/93)
- perform\_at and perform\_async do not unique if perform\_at is in the future. [\#91](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/91)
- Latest release is breaking [\#90](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/90)
- Optimize Redis usage [\#89](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/89)
- Unique jobs sets Sidekiq testing to inline! mode [\#88](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/88)
- Test suite unclear on what happens when duplicate job is attempted [\#84](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/84)
- Change log level to info rather than warn [\#80](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/80)
- Jobs are unlocked if they fail and are retried [\#77](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/77)
- Usage of sidekiq-unique-jobs with activejob [\#76](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/76)
- If a job is deleted from the enqueued list, it's still unique and new jobs can't be added. [\#74](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/74)
- Incorrect README re: uniqueness time? [\#73](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/73)
- Sidekiq::Testing inline detection assumes you're always using inline testing [\#71](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/71)
- unique\_args\_enabled has been deprecated, nothing in readme [\#70](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/70)
-  The second job does not run, even if it has different arguments [\#69](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/69)
- Jobs not being executed anymore?? [\#65](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/65)
- mock\_redis and the mess [\#62](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/62)
- What is the exact behavior? [\#47](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/47)
- Throttling jobs [\#39](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/39)
- undefined method `get\_sidekiq\_options' for "MyScheduledWorker":String  [\#27](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/27)
- Crash handling [\#14](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/14)
- Missing info from README [\#6](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/6)

**Merged pull requests:**

- Allow job with jid matching unique lock to pass unique check [\#105](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/105) ([deltaroe](https://github.com/deltaroe))
- Prevent Jobs from deleting mutexes they don't own [\#96](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/96) ([pik](https://github.com/pik))
- Add after unlock hook [\#92](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/92) ([HParker](https://github.com/HParker))
- Do not unlock on sidekiq shutdown [\#87](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/87) ([deltaroe](https://github.com/deltaroe))
- Remove no-op code, protect global space from test code [\#86](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/86) ([stevenjonescgm](https://github.com/stevenjonescgm))
- Remove unique lock when executing and clearing jobs in sidekiq fake mode [\#83](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/83) ([crberube](https://github.com/crberube))
- Fix tests. Tests with latest sidekiq versions and ruby versions [\#82](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/82) ([simonoff](https://github.com/simonoff))
- Duplicate Payload logging configuration [\#81](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/81) ([jprincipe](https://github.com/jprincipe))
- output log if not unique [\#79](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/79) ([sonots](https://github.com/sonots))
- Checking Sidekiq::Testing.inline? on testing strategy and connector [\#75](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/75) ([Draiken](https://github.com/Draiken))

## [v3.0.11](https://github.com/mhenrixon/sidekiq-unique-jobs/tree/v3.0.11) (2014-12-15)

[Full Changelog](https://github.com/mhenrixon/sidekiq-unique-jobs/compare/v3.0.10...v3.0.11)

**Closed issues:**

- ConnectionPool used incorrectly - causes deadlocks [\#66](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/66)
- undefined `configuration` when using .configure [\#64](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/64)

**Merged pull requests:**

- Use ConnectionPool blocks to ensure exclusive connection. Closes \#66. [\#67](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/67) ([adstage-david](https://github.com/adstage-david))

## [v3.0.10](https://github.com/mhenrixon/sidekiq-unique-jobs/tree/v3.0.10) (2014-11-19)

[Full Changelog](https://github.com/mhenrixon/sidekiq-unique-jobs/compare/v3.0.9...v3.0.10)

**Closed issues:**

- LoadError: cannot load such file -- mock\_redis [\#60](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/60)
- The deprecation message is unclear and unnecessary [\#59](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/59)

**Merged pull requests:**

- Added method name to depreciation warning message [\#61](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/61) ([jamesbowles](https://github.com/jamesbowles))

## [v3.0.9](https://github.com/mhenrixon/sidekiq-unique-jobs/tree/v3.0.9) (2014-11-05)

[Full Changelog](https://github.com/mhenrixon/sidekiq-unique-jobs/compare/v3.0.3...v3.0.9)

**Closed issues:**

- sidekiq-unique-jobs prevents not unique jobs creation event with sidekiq inline test mode [\#58](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/58)
- mock redis dependency [\#55](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/55)
- Unique key inconsistency between server and client [\#48](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/48)
- Example Test using Sidekiq::Testing.inline [\#44](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/44)
- Will a second job lose if the job is already queued, or is already scheduled? [\#43](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/43)
- Can you update the change log? [\#42](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/42)

**Merged pull requests:**

- Refactoring connectors to use them in client and server [\#56](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/56) ([salrepe](https://github.com/salrepe))
- Fix dependency error in inline testing connector [\#54](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/54) ([salrepe](https://github.com/salrepe))
- Add extension to Sidekiq API that is uniqueness-aware [\#52](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/52) ([rickenharp](https://github.com/rickenharp))

## [v3.0.3](https://github.com/mhenrixon/sidekiq-unique-jobs/tree/v3.0.3) (2014-11-03)

[Full Changelog](https://github.com/mhenrixon/sidekiq-unique-jobs/compare/v3.0.2...v3.0.3)

**Closed issues:**

- is mock\_redis really a runtime dependency? [\#46](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/46)

**Merged pull requests:**

- Unlock testing inline jobs like normal ones [\#53](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/53) ([salrepe](https://github.com/salrepe))
- Declare mock\_redis as development dependency instead of runtime one [\#51](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/51) ([phuongnd08](https://github.com/phuongnd08))

## [v3.0.2](https://github.com/mhenrixon/sidekiq-unique-jobs/tree/v3.0.2) (2014-06-08)

[Full Changelog](https://github.com/mhenrixon/sidekiq-unique-jobs/compare/v3.0.1...v3.0.2)

**Closed issues:**

- Add unique job key to the message json [\#40](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/40)

**Merged pull requests:**

- Add the unique hash to the message for use by the workers. [\#41](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/41) ([sullimander](https://github.com/sullimander))

## [v3.0.1](https://github.com/mhenrixon/sidekiq-unique-jobs/tree/v3.0.1) (2014-06-08)

[Full Changelog](https://github.com/mhenrixon/sidekiq-unique-jobs/compare/v2.7.0...v3.0.1)

**Closed issues:**

- Support for sidekiq 3? [\#34](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/34)
- Short jobs are not unique for the given time window [\#33](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/33)
- Not all sidekiq:sidekiq\_unique keys are removed from Redis [\#31](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/31)
- What does uniqueness mean in case of this gem? [\#30](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/30)
- Server middleware removes payload hash key before expiration [\#26](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/26)
- Lock remains when running with Sidekiq::Testing.inline! [\#23](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/23)
- What is the use case for the uniqueness window? [\#22](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/22)
- clarification on unique\_args [\#20](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/20)
- payload\_hash staying around [\#13](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/13)

**Merged pull requests:**

- Fix repo URLs for badges [\#38](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/38) ([felixbuenemann](https://github.com/felixbuenemann))
- Clarify README about unique expiration [\#36](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/36) ([spacemunkay](https://github.com/spacemunkay))
- Add option to make jobs unique on all queues [\#32](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/32) ([robinmessage](https://github.com/robinmessage))
- Fix homepage in gemspec [\#29](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/29) ([tmaier](https://github.com/tmaier))

## [v2.7.0](https://github.com/mhenrixon/sidekiq-unique-jobs/tree/v2.7.0) (2013-11-24)

[Full Changelog](https://github.com/mhenrixon/sidekiq-unique-jobs/compare/v2.3.2...v2.7.0)

**Closed issues:**

- Sidekiq tests failed when sidekiq-unique-jobs is used [\#24](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/24)
- Redis not mocked in testing [\#18](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/18)
- Scheduled Unique Jobs Not Being Enqueued [\#15](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/15)
- Retries duplicates unique jobs [\#5](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/5)
- Middleware not added to chain? [\#2](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/2)

**Merged pull requests:**

- Make unlock/yield order configurable. [\#21](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/21) ([endofunky](https://github.com/endofunky))
- Rely on Sidekiq's String\#constantize extension instead of rolling our own [\#19](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/19) ([disbelief](https://github.com/disbelief))
- Attempt to constantize String `worker_class` arguments passed to client middleware [\#17](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/17) ([disbelief](https://github.com/disbelief))
- Compatibility with Sidekiq 2.12.1 Scheduled Jobs [\#16](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/16) ([lsimoneau](https://github.com/lsimoneau))
- Allow worker to specify which arguments to include in uniquing hash [\#12](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/12) ([sax](https://github.com/sax))
- Add support for unique when using Sidekiq's delay function [\#11](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/11) ([eduardosasso](https://github.com/eduardosasso))
- Adding the unique prefix option [\#8](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/8) ([KensoDev](https://github.com/KensoDev))
- Remove unnecessary log messages [\#7](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/7) ([marclennox](https://github.com/marclennox))

## [v2.3.2](https://github.com/mhenrixon/sidekiq-unique-jobs/tree/v2.3.2) (2012-09-27)

[Full Changelog](https://github.com/mhenrixon/sidekiq-unique-jobs/compare/v2.2.1...v2.3.2)

**Closed issues:**

- Scheduled workers [\#1](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/1)

**Merged pull requests:**

- Fix multiple bugs, cleaned up dependencies, and added a feature [\#4](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/4) ([kemper-blinq](https://github.com/kemper-blinq))
- Dependency on sidekiq 2.2.0 and up [\#3](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/3) ([philostler](https://github.com/philostler))

## [v2.2.1](https://github.com/mhenrixon/sidekiq-unique-jobs/tree/v2.2.1) (2012-08-19)

[Full Changelog](https://github.com/mhenrixon/sidekiq-unique-jobs/compare/v2.2.0...v2.2.1)

## [v2.2.0](https://github.com/mhenrixon/sidekiq-unique-jobs/tree/v2.2.0) (2012-08-19)

[Full Changelog](https://github.com/mhenrixon/sidekiq-unique-jobs/compare/v2.1.0...v2.2.0)

## [v2.1.0](https://github.com/mhenrixon/sidekiq-unique-jobs/tree/v2.1.0) (2012-08-07)

[Full Changelog](https://github.com/mhenrixon/sidekiq-unique-jobs/compare/03d8c0ebb6b5978a4604b179ec0cd70b6ba4662a...v2.1.0)



\* *This Changelog was automatically generated by [github_changelog_generator](https://github.com/github-changelog-generator/github-changelog-generator)*
