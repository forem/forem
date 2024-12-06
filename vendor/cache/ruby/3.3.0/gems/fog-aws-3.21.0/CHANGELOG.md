# Changelog

## [v3.21.0](https://github.com/fog/fog-aws/tree/v3.21.0) (2023-09-29)

[Full Changelog](https://github.com/fog/fog-aws/compare/v3.20.0...v3.21.0)

**Closed issues:**

- Fog::AWS::Storage default retry behaviour guarantees 6s delay for 4xx class responses [\#690](https://github.com/fog/fog-aws/issues/690)

**Merged pull requests:**

- Fog::AWS::Storage don't retry client errors [\#691]((https://github.com/fog/fog-aws/pull/691) ([rahim](https://github.com/rahim))

## [v3.20.0](https://github.com/fog/fog-aws/tree/v3.20.0) (2023-09-27)

[Full Changelog](https://github.com/fog/fog-aws/compare/v3.19.0...v3.20.0)

**Closed issues:**

- Fog::AWS::Storage::File x-amz-request-id and x-amz-id-2 header reflection [\#688](https://github.com/fog/fog-aws/issues/688)
- When using IRSA on `Fog::Storage`, output `Unrecognized arguments: sts_endpoint` warning  [\#683](https://github.com/fog/fog-aws/issues/683)
- Is it possible to add `DurationSeconds` in CredentialFetcher ? [\#682](https://github.com/fog/fog-aws/issues/682)

**Merged pull requests:**

- Fog::AWS::Storage::File - fix request id header reflection [\#689](https://github.com/fog/fog-aws/pull/689) ([rahim](https://github.com/rahim))
- Bump actions/checkout from 3 to 4 [\#687](https://github.com/fog/fog-aws/pull/687) ([dependabot[bot]](https://github.com/apps/dependabot))
- add c6a, c6i, c6id, m6a,m6i, m6id, and r6a, r6i, r6id support [\#686](https://github.com/fog/fog-aws/pull/686) ([ashivadi](https://github.com/ashivadi))
- Align the parameters for `AssumeRoleWithWebIdentity` action [\#685](https://github.com/fog/fog-aws/pull/685) ([marshluca](https://github.com/marshluca))
- Prevent `Unrecognized arguments: sts_endpoint` warning [\#684](https://github.com/fog/fog-aws/pull/684) ([nekomaho](https://github.com/nekomaho))
- CI against Ruby 3.2 [\#681](https://github.com/fog/fog-aws/pull/681) ([y-yagi](https://github.com/y-yagi))
- Change method sync\_clock\_url to use localstack set a different port [\#680](https://github.com/fog/fog-aws/pull/680) ([fabiodallazen](https://github.com/fabiodallazen))

## [v3.19.0](https://github.com/fog/fog-aws/tree/v3.19.0) (2023-05-18)

[Full Changelog](https://github.com/fog/fog-aws/compare/v3.18.0...v3.19.0)

**Merged pull requests:**

- gopalcoupa:add-me-central-1 [\#679](https://github.com/fog/fog-aws/pull/679)
- Fix S3 Transfer Acceleration [\#676](https://github.com/fog/fog-aws/pull/676)
- configure connection_options to improve s3 retry see https://github.com/fog/fog-aws/issues/674 [\#675](https://github.com/fog/fog-aws/pull/675)
- s3: remove hardcoded host [\#673](https://github.com/fog/fog-aws/pull/673)
- Bump actions/stale from 7 to 8 [\#671](https://github.com/fog/fog-aws/pull/671)

## [v3.18.0](https://github.com/fog/fog-aws/tree/v3.18.0) (2023-02-16)

[Full Changelog](https://github.com/fog/fog-aws/compare/v3.17.0...v3.18.0)

**Merged pull requests:**

- Only compute SSE-C headers when needed in multipart upload [\#669](https://github.com/fog/fog-aws/pull/669) ([stanhu](https://github.com/stanhu))

## [v3.17.0](https://github.com/fog/fog-aws/tree/v3.17.0) (2023-02-09)

[Full Changelog](https://github.com/fog/fog-aws/compare/v3.16.0...v3.17.0)

**Merged pull requests:**

- Support disabling of Content-MD5 for FIPS [\#668](https://github.com/fog/fog-aws/pull/668) ([stanhu](https://github.com/stanhu))

## [v3.16.0](https://github.com/fog/fog-aws/tree/v3.16.0) (2023-01-26)

[Full Changelog](https://github.com/fog/fog-aws/compare/v3.15.0...v3.16.0)

**Closed issues:**

- README lists incorrect usage of IAM auth [\#663](https://github.com/fog/fog-aws/issues/663)
- How can i config to use s3 in localstack [\#657](https://github.com/fog/fog-aws/issues/657)
- Fog::Storage::AWS::Files#each always iterates over entire collection [\#232](https://github.com/fog/fog-aws/issues/232)
- superclass mismatch for class AWS [\#655](https://github.com/fog/fog-aws/issues/655)
- Lambda IAM Role Not Working [\#650](https://github.com/fog/fog-aws/issues/650)

**Merged pull requests:**

- adding missing region ap-southeast-4 [\#665](https://github.com/fog/fog-aws/pull/665) ([emptyhammond](https://github.com/emptyhammond))
o
- adding missing region eu-south-2 [\#662](https://github.com/fog/fog-aws/pull/662) ([ivangool](https://github.com/ivangool))
- Bump actions/dependency-review-action from 2 to 3 [\#659](https://github.com/fog/fog-aws/pull/659) ([dependabot[bot]](https://github.com/apps/dependabot))
- Update aws.rb [\#658](https://github.com/fog/fog-aws/pull/658) ([ivangool](https://github.com/ivangool))
- Bump actions/stale from 5 to 6 [\#656](https://github.com/fog/fog-aws/pull/656) ([dependabot[bot]](https://github.com/apps/dependabot))

## [v3.15.0](https://github.com/fog/fog-aws/tree/v3.15.0) (2022-09-12)

[Full Changelog](https://github.com/fog/fog-aws/compare/v3.14.0...v3.15.0)

**Closed issues:**

- URI.decode is obsolete \(and not available in Ruby 3.0\) [\#653](https://github.com/fog/fog-aws/issues/653)
- S3: File copy not working outside us-east-1 region [\#645](https://github.com/fog/fog-aws/issues/645)
- Unable to list, update and remove RDS tags in AWS GovCloud Account regions. [\#644](https://github.com/fog/fog-aws/issues/644)
- Documentation links broken / 404 [\#642](https://github.com/fog/fog-aws/issues/642)

**Merged pull requests:**

- Replace URI.decode as obsolete, and removed in Ruby 3.0 [\#654](https://github.com/fog/fog-aws/pull/654) ([kuahyeow](https://github.com/kuahyeow))
- Fix typo in readme [\#652](https://github.com/fog/fog-aws/pull/652) ([geemus](https://github.com/geemus))
- change sync\_clock to plain GET [\#651](https://github.com/fog/fog-aws/pull/651) ([duckworth](https://github.com/duckworth))
- Update README file with download url example [\#649](https://github.com/fog/fog-aws/pull/649) ([lucasocon](https://github.com/lucasocon))
- Bump actions/dependency-review-action from 1 to 2 [\#648](https://github.com/fog/fog-aws/pull/648) ([dependabot[bot]](https://github.com/apps/dependabot))
- add x2gd and t4g instance flavours [\#647](https://github.com/fog/fog-aws/pull/647) ([mushyy](https://github.com/mushyy))
- Fix a typo in CHANGELOG [\#646](https://github.com/fog/fog-aws/pull/646) ([y-yagi](https://github.com/y-yagi))

## [v3.14.0](https://github.com/fog/fog-aws/tree/v3.14.0) (2022-05-09)

[Full Changelog](https://github.com/fog/fog-aws/compare/v3.13.0...v3.14.0)

**Closed issues:**

- Add a special note to the documentation around the danger of using directory.get [\#633](https://github.com/fog/fog-aws/issues/633)

**Merged pull requests:**

- RDS tags issue in AWS GovCloud Account regions. [\#643](https://github.com/fog/fog-aws/pull/643) ([svavhal](https://github.com/svavhal))
- Create codeql.yml [\#641](https://github.com/fog/fog-aws/pull/641) ([naveensrinivasan](https://github.com/naveensrinivasan))
- chore\(deps\): Included dependency review [\#640](https://github.com/fog/fog-aws/pull/640) ([naveensrinivasan](https://github.com/naveensrinivasan))
- Bump actions/stale from 4 to 5 [\#639](https://github.com/fog/fog-aws/pull/639) ([dependabot[bot]](https://github.com/apps/dependabot))
- Set permissions for GitHub actions [\#638](https://github.com/fog/fog-aws/pull/638) ([naveensrinivasan](https://github.com/naveensrinivasan))
- Add option to control IAM credential refresh [\#637](https://github.com/fog/fog-aws/pull/637) ([gl-gh-hchouraria](https://github.com/gl-gh-hchouraria))
- Add warning messages around directories.get [\#636](https://github.com/fog/fog-aws/pull/636) ([orrin-naylor-instacart](https://github.com/orrin-naylor-instacart))
- Bump actions/checkout from 2.4.0 to 3 [\#632](https://github.com/fog/fog-aws/pull/632) ([dependabot[bot]](https://github.com/apps/dependabot))
- Add Ruby 3.1 to the CI matrix [\#631](https://github.com/fog/fog-aws/pull/631) ([petergoldstein](https://github.com/petergoldstein))

## [v3.13.0](https://github.com/fog/fog-aws/tree/v3.13.0) (2022-02-13)

[Full Changelog](https://github.com/fog/fog-aws/compare/v3.12.0...v3.13.0)

**Closed issues:**

- Please include all files required for running tests in the gem [\#625](https://github.com/fog/fog-aws/issues/625)
- Using Hitachi compatible S3 and still see the AWS S3 host  [\#624](https://github.com/fog/fog-aws/issues/624)
- Spawn compute node with Elastic Inference [\#617](https://github.com/fog/fog-aws/issues/617)

**Merged pull requests:**

- Drop ipaddress dependency in favor of built in ipaddr [\#630](https://github.com/fog/fog-aws/pull/630) ([ekohl](https://github.com/ekohl))
- Exclude test files from gem [\#629](https://github.com/fog/fog-aws/pull/629) ([ursm](https://github.com/ursm))
- Add Truffleruby head to CI [\#628](https://github.com/fog/fog-aws/pull/628) ([gogainda](https://github.com/gogainda))
- Bump actions/checkout from 2.3.5 to 2.4.0 [\#627](https://github.com/fog/fog-aws/pull/627) ([dependabot[bot]](https://github.com/apps/dependabot))
- Update Fog::AWS::Storage::File\#body [\#626](https://github.com/fog/fog-aws/pull/626) ([10io](https://github.com/10io))
- Bump actions/checkout from 2.3.4 to 2.3.5 [\#623](https://github.com/fog/fog-aws/pull/623) ([dependabot[bot]](https://github.com/apps/dependabot))
- Add json files to the gem file [\#622](https://github.com/fog/fog-aws/pull/622) ([acant](https://github.com/acant))

## [v3.12.0](https://github.com/fog/fog-aws/tree/v3.12.0) (2021-08-23)

[Full Changelog](https://github.com/fog/fog-aws/compare/v3.11.0...v3.12.0)

**Merged pull requests:**

-  Add support for regional STS endpoints [\#620](https://github.com/fog/fog-aws/pull/620) ([stanhu](https://github.com/stanhu))
- Add IPv6 support for Ingress Security Groups [\#619](https://github.com/fog/fog-aws/pull/619) ([p8](https://github.com/p8))
- Separate CHANGELOG entry for 3.11.0 [\#618](https://github.com/fog/fog-aws/pull/618) ([sunny](https://github.com/sunny))

## [v3.11.0](https://github.com/fog/fog-aws/tree/v3.11.0) (2021-08-05)

[Full Changelog](https://github.com/fog/fog-aws/compare/v3.10.0...v3.11.0)

**Closed issues:**

- Support for Regional STS Endpoints [\#604](https://github.com/fog/fog-aws/issues/604)
- Pass tags when creating EBS ? [\#603](https://github.com/fog/fog-aws/issues/603)
- S3 multiple delete api should handle delete for multiple versions for a single object [\#598](https://github.com/fog/fog-aws/issues/598)
- Fog does not return error from s3 [\#586](https://github.com/fog/fog-aws/issues/586)
- Add support for r6g and c6g instance types [\#580](https://github.com/fog/fog-aws/issues/580)
- Using internal S3 provider ... and something funky is going on! [\#575](https://github.com/fog/fog-aws/issues/575)
- How to upload File to S3 with with accelerate? [\#554](https://github.com/fog/fog-aws/issues/554)
- How to use assume\_role\_with\_web\_identity auth for S3 storage? [\#543](https://github.com/fog/fog-aws/issues/543)
- Fog::AWS::Glacier::TreeHash::add\_part works only sometimes [\#520](https://github.com/fog/fog-aws/issues/520)
- fog-aws: Fog::AWS::Glacier::Job doesn't support RetrievalByteRange [\#519](https://github.com/fog/fog-aws/issues/519)
- Path style is being deprecated [\#516](https://github.com/fog/fog-aws/issues/516)
-  Fog::DNS::AWS can't read zones [\#513](https://github.com/fog/fog-aws/issues/513)
- Lambda Parser can't handle VPC config, containing array of hash values [\#509](https://github.com/fog/fog-aws/issues/509)
- Excon::Error::Forbidden: Expected\(200\) \<=\> Actual\(403 Forbidden\)  [\#508](https://github.com/fog/fog-aws/issues/508)
- file.save does not work with STDIN [\#500](https://github.com/fog/fog-aws/issues/500)
- ELBv2 Support ? [\#489](https://github.com/fog/fog-aws/issues/489)
- S3 Select Support? [\#484](https://github.com/fog/fog-aws/issues/484)
- nil:NilClass error [\#483](https://github.com/fog/fog-aws/issues/483)
- Mocks for VM creation require access and secret key when using instance profiles [\#482](https://github.com/fog/fog-aws/issues/482)
- Always use bucket virtual hostname? [\#464](https://github.com/fog/fog-aws/issues/464)
- Spot instance creation : Support for BlockDurationMinutes [\#461](https://github.com/fog/fog-aws/issues/461)
- How can I remove the `Content-Encoding` metadata properties if I upload from fog [\#447](https://github.com/fog/fog-aws/issues/447)
- AWS::ECS with `use_iam_profile` errors out [\#441](https://github.com/fog/fog-aws/issues/441)
- Option to turn off Warnings [\#426](https://github.com/fog/fog-aws/issues/426)
- Accessing AWS S3 using EC2 Instance Profile [\#423](https://github.com/fog/fog-aws/issues/423)
- Support step and target tracking auto scaling policies [\#422](https://github.com/fog/fog-aws/issues/422)
- could not create ec2 volume with custom encryption key, volume only create with default 'aws/ebs' encryption key [\#420](https://github.com/fog/fog-aws/issues/420)
- Download File with content\_disposition [\#418](https://github.com/fog/fog-aws/issues/418)
- Fog::Compute::AWS::Error iamInstanceProfile.name is invalid [\#410](https://github.com/fog/fog-aws/issues/410)
- Mocks for EC2 instance creation do not behave as expected [\#404](https://github.com/fog/fog-aws/issues/404)
- Cannot copy an encrypted snapshot from one account to another account [\#398](https://github.com/fog/fog-aws/issues/398)
-  Fog::Compute::AWS::Image\#deregister ignores non-root snapshots. [\#380](https://github.com/fog/fog-aws/issues/380)
- AWS S3 overwrites files with same name [\#378](https://github.com/fog/fog-aws/issues/378)
- Support S3 object tagging [\#377](https://github.com/fog/fog-aws/issues/377)
- Reqeust to support Aws::DynamoDBStreams [\#373](https://github.com/fog/fog-aws/issues/373)
- Not all Rds versions and Instance Types are rendered [\#371](https://github.com/fog/fog-aws/issues/371)
- Tag instances upon creation of new instance [\#359](https://github.com/fog/fog-aws/issues/359)
- Creating instances in AWS fails with Socket Error [\#352](https://github.com/fog/fog-aws/issues/352)
- `NameError: uninitialized constant Fog::ServicesMixin` when requiring `fog/storage` [\#345](https://github.com/fog/fog-aws/issues/345)
- Add full support for target groups [\#328](https://github.com/fog/fog-aws/issues/328)
- Fog transfer acceleration endpoints [\#303](https://github.com/fog/fog-aws/issues/303)
- "Fog::DNS\[:aws\] | change\_resource\_record\_sets \(aws, dns\)" test suite flaky [\#301](https://github.com/fog/fog-aws/issues/301)
- Cross account access using IAM role [\#294](https://github.com/fog/fog-aws/issues/294)
- Write timeout trying to upload a large file to S3 [\#291](https://github.com/fog/fog-aws/issues/291)
- Support Autoscaling lifecycle hooks [\#289](https://github.com/fog/fog-aws/issues/289)
- directories ignore region option [\#287](https://github.com/fog/fog-aws/issues/287)
- Feature: Access logs for ELB [\#271](https://github.com/fog/fog-aws/issues/271)
- S3: retry on 500 internal server error [\#264](https://github.com/fog/fog-aws/issues/264)
- Alias for server side encryption not working [\#260](https://github.com/fog/fog-aws/issues/260)
- InvalidParameterCombination =\> You cannot move a DB instance with Single-Az enabled to a VPC \(Fog::AWS::RDS::Error\) [\#255](https://github.com/fog/fog-aws/issues/255)
- Using STS [\#253](https://github.com/fog/fog-aws/issues/253)
- Auto Scaling Group does not enable metrics [\#251](https://github.com/fog/fog-aws/issues/251)
- aws has no storage service [\#248](https://github.com/fog/fog-aws/issues/248)
- Timeouts on Compute\#describe\_volumes due to extreme numbers of volumes [\#244](https://github.com/fog/fog-aws/issues/244)
- Support CreateReusableDelegationSet [\#243](https://github.com/fog/fog-aws/issues/243)
- Tags server creation in Mock vs Real [\#239](https://github.com/fog/fog-aws/issues/239)
- Excon::Errors::SocketError Broken pipe \(Errno::EPIPE\) when use Activeadmin upload image by nested form [\#237](https://github.com/fog/fog-aws/issues/237)
- Fog Mock doesn't update [\#236](https://github.com/fog/fog-aws/issues/236)
- ECS service\_update does not support "deploymentConfig" [\#234](https://github.com/fog/fog-aws/issues/234)
- Fog::Storage::AWS::Files\#each always iterates over entire collection [\#232](https://github.com/fog/fog-aws/issues/232)
- repeated bucket name in the URL on AWS and issue with :path\_style [\#228](https://github.com/fog/fog-aws/issues/228)
- Already initialized constant warnings [\#212](https://github.com/fog/fog-aws/issues/212)
- SQS API version is outdated [\#198](https://github.com/fog/fog-aws/issues/198)
- Problem when using irb [\#195](https://github.com/fog/fog-aws/issues/195)
- compute.servers \(via DescribeInstances\) does not include tags reliably [\#192](https://github.com/fog/fog-aws/issues/192)
- EBS create volume io1 or gp2 [\#186](https://github.com/fog/fog-aws/issues/186)
- Aws cloudformation stack-policy-body [\#179](https://github.com/fog/fog-aws/issues/179)
- EXCON\_DEBUG and DEBUG env variables do not help debug -S key issues [\#177](https://github.com/fog/fog-aws/issues/177)
- AWS4 SignatureDoesNotMatch if header contains two spaces [\#160](https://github.com/fog/fog-aws/issues/160)
- Add support for elasticache redis replication groups [\#136](https://github.com/fog/fog-aws/issues/136)
- Getting SignatureDoesNotMatch error with eu-central-1 [\#127](https://github.com/fog/fog-aws/issues/127)
- Cannot saving auto scaling group [\#125](https://github.com/fog/fog-aws/issues/125)
- fog-aws not working with dynamoDB Local [\#118](https://github.com/fog/fog-aws/issues/118)
- Fog::Compute::AWS::Error InvalidParameterValue =\> secondary-addresses [\#115](https://github.com/fog/fog-aws/issues/115)
- Is there an equivalent to describe-instance-status? [\#66](https://github.com/fog/fog-aws/issues/66)
- No usage instructions in Readme [\#64](https://github.com/fog/fog-aws/issues/64)
- AWS - distributionConfig.enabled' failed to satisfy constraint: Member must not be null [\#48](https://github.com/fog/fog-aws/issues/48)
- Clarify versioning on README [\#42](https://github.com/fog/fog-aws/issues/42)
- AWS SQS AddPermission API missing [\#26](https://github.com/fog/fog-aws/issues/26)
- AWS China region [\#25](https://github.com/fog/fog-aws/issues/25)
- AWS CloudFormation ListStacks options [\#24](https://github.com/fog/fog-aws/issues/24)
- Setting region of AWS::Compute after initialization [\#23](https://github.com/fog/fog-aws/issues/23)
- Support AWS Support API [\#22](https://github.com/fog/fog-aws/issues/22)
- InvalidClientTokenId =\> The security token included in the request is invalid [\#21](https://github.com/fog/fog-aws/issues/21)
- Change architecture attribute in AWS::Compute::Server model [\#20](https://github.com/fog/fog-aws/issues/20)
- Add support for Amazon Kinesis [\#19](https://github.com/fog/fog-aws/issues/19)
- Bring AWS CloudFront API Models/Requests up to date [\#17](https://github.com/fog/fog-aws/issues/17)
- AWS security group tests have become unstable [\#16](https://github.com/fog/fog-aws/issues/16)
- AWS auto scaling: availability zones are not a required parameter [\#15](https://github.com/fog/fog-aws/issues/15)
- Is anyone going to add support for AWS ElasticTranscoder [\#14](https://github.com/fog/fog-aws/issues/14)
- add missing attributes to aws describe\_reserved\_instances parser [\#13](https://github.com/fog/fog-aws/issues/13)
- AWS AutoScaling group min\_size & max\_size getting set to 0 [\#12](https://github.com/fog/fog-aws/issues/12)
- auto\_scaling\_group.instances does not return only instances for that group [\#11](https://github.com/fog/fog-aws/issues/11)
- Why are the credential keys not generalized?  [\#10](https://github.com/fog/fog-aws/issues/10)
- Invalid XML Character in S3 Response [\#8](https://github.com/fog/fog-aws/issues/8)
- reading s3 upload progress [\#7](https://github.com/fog/fog-aws/issues/7)
- delete\_on\_termination=true attribute on new volume is not set on create [\#6](https://github.com/fog/fog-aws/issues/6)
- user\_data is still base64 encoded in Real launch\_configurations [\#5](https://github.com/fog/fog-aws/issues/5)

**Merged pull requests:**

- Add storage option to configure multipart put/copy [\#616](https://github.com/fog/fog-aws/pull/616) ([slonopotamus](https://github.com/slonopotamus))
- Bump actions/stale from 3.0.19 to 4 [\#615](https://github.com/fog/fog-aws/pull/615) ([dependabot[bot]](https://github.com/apps/dependabot))
- Update file.rb [\#613](https://github.com/fog/fog-aws/pull/613) ([iqre8](https://github.com/iqre8))
- fix storage for ruby 3.0 [\#611](https://github.com/fog/fog-aws/pull/611) ([vincentjoseph](https://github.com/vincentjoseph))
- Implement AWS TagSpecifications \(closes \#603\) [\#610](https://github.com/fog/fog-aws/pull/610) ([eLvErDe](https://github.com/eLvErDe))
- Bump actions/stale from 3.0.18 to 3.0.19 [\#609](https://github.com/fog/fog-aws/pull/609) ([dependabot[bot]](https://github.com/apps/dependabot))
- Bump actions/stale from 3 to 3.0.18 [\#608](https://github.com/fog/fog-aws/pull/608) ([dependabot[bot]](https://github.com/apps/dependabot))
- Bump actions/checkout from 2 to 2.3.4 [\#607](https://github.com/fog/fog-aws/pull/607) ([dependabot[bot]](https://github.com/apps/dependabot))
- drop git in gemspec [\#602](https://github.com/fog/fog-aws/pull/602) ([abrahamparayil](https://github.com/abrahamparayil))
- Update rubyzip requirement from ~\> 1.3.0 to ~\> 2.3.0 [\#601](https://github.com/fog/fog-aws/pull/601) ([dependabot[bot]](https://github.com/apps/dependabot))

## [v3.10.0](https://github.com/fog/fog-aws/tree/v3.10.0) (2021-03-22)

[Full Changelog](https://github.com/fog/fog-aws/compare/v3.9.0...v3.10.0)

**Closed issues:**

- Fog::AWS::Storage timeout against S3 [\#599](https://github.com/fog/fog-aws/issues/599)
- Incorrect bucket redirection URL generation  [\#594](https://github.com/fog/fog-aws/issues/594)
- Fully Support SSE-C encryption [\#571](https://github.com/fog/fog-aws/issues/571)
- Enable hibernation on creation of ec2 instance [\#566](https://github.com/fog/fog-aws/issues/566)
- Tests broken with fog-core 2.1.0 [\#504](https://github.com/fog/fog-aws/issues/504)
- changelog? [\#471](https://github.com/fog/fog-aws/issues/471)
- How to use iam\_instance\_profile? [\#342](https://github.com/fog/fog-aws/issues/342)
- how to support additional aws regions, e.g. cn-north-1 [\#164](https://github.com/fog/fog-aws/issues/164)
- Still empty content-encoding when it is not set [\#130](https://github.com/fog/fog-aws/issues/130)

**Merged pull requests:**

- Handle multiple versions of objects in multiple delete request [\#600](https://github.com/fog/fog-aws/pull/600) ([shanu-kr](https://github.com/shanu-kr))
- Add Truffleruby head to CI [\#596](https://github.com/fog/fog-aws/pull/596) ([gogainda](https://github.com/gogainda))
- Fixes domain name duplication in url [\#593](https://github.com/fog/fog-aws/pull/593) ([midhunkrishna](https://github.com/midhunkrishna))

## [v3.9.0](https://github.com/fog/fog-aws/tree/v3.9.0) (2021-03-02)

[Full Changelog](https://github.com/fog/fog-aws/compare/v3.8.0...v3.9.0)

**Merged pull requests:**

- Fix handling of lowercased HTTP headers [\#597](https://github.com/fog/fog-aws/pull/597) ([stanhu](https://github.com/stanhu))
- Generate a default session name if one is not provided [\#595](https://github.com/fog/fog-aws/pull/595) ([stanhu](https://github.com/stanhu))
- Enable test on Ruby 3.0 [\#591](https://github.com/fog/fog-aws/pull/591) ([voxik](https://github.com/voxik))

## [v3.8.0](https://github.com/fog/fog-aws/tree/v3.8.0) (2021-01-13)

[Full Changelog](https://github.com/fog/fog-aws/compare/v3.7.0...v3.8.0)

**Closed issues:**

- Getting Auth failure Exception for non enabled AWS regions in AWS account. [\#585](https://github.com/fog/fog-aws/issues/585)

**Merged pull requests:**

- Filter unknown UploadPartCopy parameters [\#589](https://github.com/fog/fog-aws/pull/589) ([stanhu](https://github.com/stanhu))
- Fix NameError in multipart copy [\#588](https://github.com/fog/fog-aws/pull/588) ([stanhu](https://github.com/stanhu))
- Rewind pointer if file is eof on put\_object mock [\#587](https://github.com/fog/fog-aws/pull/587) ([ekulz](https://github.com/ekulz))
- Update .travis.yml [\#584](https://github.com/fog/fog-aws/pull/584) ([nageshlop](https://github.com/nageshlop))

## [v3.7.0](https://github.com/fog/fog-aws/tree/v3.7.0) (2020-12-01)

[Full Changelog](https://github.com/fog/fog-aws/compare/v3.6.7...v3.7.0)

**Closed issues:**

- File\#copy does not support files above 5 GB [\#577](https://github.com/fog/fog-aws/issues/577)
- fog-aws: AWS extended length resource ID issues \(8-\>18\) [\#517](https://github.com/fog/fog-aws/issues/517)

**Merged pull requests:**

- Add all m6gd, r6g, r6gd, c6g, and c6gd instance classes [\#582](https://github.com/fog/fog-aws/pull/582) ([calebwoofenden](https://github.com/calebwoofenden))
- Test Ruby v2.6.6 and v2.7.2 in CI [\#581](https://github.com/fog/fog-aws/pull/581) ([stanhu](https://github.com/stanhu))
- Add multi-threaded support for File\#copy [\#579](https://github.com/fog/fog-aws/pull/579) ([stanhu](https://github.com/stanhu))
- Add support for multipart Fog::AWS::Storage::File\#copy [\#578](https://github.com/fog/fog-aws/pull/578) ([stanhu](https://github.com/stanhu))
- Add AssumeRoleWithWebIdentity to fetch\_credentials [\#576](https://github.com/fog/fog-aws/pull/576) ([jpac-run](https://github.com/jpac-run))

## [v3.6.7](https://github.com/fog/fog-aws/tree/v3.6.7) (2020-08-26)

[Full Changelog](https://github.com/fog/fog-aws/compare/v3.6.6...v3.6.7)

**Merged pull requests:**

- S3 dot Region endpoint structure applied [\#574](https://github.com/fog/fog-aws/pull/574) ([gharutyunyan-vineti](https://github.com/gharutyunyan-vineti))

## [v3.6.6](https://github.com/fog/fog-aws/tree/v3.6.6) (2020-06-23)

[Full Changelog](https://github.com/fog/fog-aws/compare/v3.6.5...v3.6.6)

**Closed issues:**

- max\_keys param in storage.directories.get.... what am I missing? [\#568](https://github.com/fog/fog-aws/issues/568)
- Fog Logs? [\#561](https://github.com/fog/fog-aws/issues/561)

**Merged pull requests:**

- added missing region EU South \(Milan\) [\#570](https://github.com/fog/fog-aws/pull/570) ([saldan](https://github.com/saldan))
- hibernation option to compute [\#569](https://github.com/fog/fog-aws/pull/569) ([taniahagan](https://github.com/taniahagan))
- Fix VPC model is\_default requires [\#567](https://github.com/fog/fog-aws/pull/567) ([biinari](https://github.com/biinari))

## [v3.6.5](https://github.com/fog/fog-aws/tree/v3.6.5) (2020-05-22)

[Full Changelog](https://github.com/fog/fog-aws/compare/v3.6.4...v3.6.5)

**Closed issues:**

- Fog::Compute::AWS is deprecated, please use Fog::AWS::Compute warning [\#565](https://github.com/fog/fog-aws/issues/565)
- Duplicate compute flavours [\#563](https://github.com/fog/fog-aws/issues/563)
- 3.6.4 does not fetch iam credentials using IMDSv2 when running from inside containers with IMDSv2 Defaults [\#560](https://github.com/fog/fog-aws/issues/560)

**Merged pull requests:**

- Fix naming of various AWS compute flavors [\#564](https://github.com/fog/fog-aws/pull/564) ([abrom](https://github.com/abrom))
- Gracefully handle failure of IMDSv2 and allow fallback to IMDSv1 [\#562](https://github.com/fog/fog-aws/pull/562) ([atyndall](https://github.com/atyndall))

## [v3.6.4](https://github.com/fog/fog-aws/tree/v3.6.4) (2020-05-14)

[Full Changelog](https://github.com/fog/fog-aws/compare/v3.6.3...v3.6.4)

**Closed issues:**

- Is fog-aws compatible with AWS Trust Services? [\#558](https://github.com/fog/fog-aws/issues/558)

**Merged pull requests:**

- Add support for IMDSv2 in CredentialFetcher [\#559](https://github.com/fog/fog-aws/pull/559) ([atyndall](https://github.com/atyndall))
- Don’t install development scripts [\#557](https://github.com/fog/fog-aws/pull/557) ([amarshall](https://github.com/amarshall))

## [v3.6.3](https://github.com/fog/fog-aws/tree/v3.6.3) (2020-04-22)

[Full Changelog](https://github.com/fog/fog-aws/compare/v3.6.2...v3.6.3)

**Merged pull requests:**

- Add South Africa \(Cape Town\) Region [\#556](https://github.com/fog/fog-aws/pull/556) ([lvangool](https://github.com/lvangool))
- Adds Instance Type r5.16xlarge and r5.8xlarge [\#555](https://github.com/fog/fog-aws/pull/555) ([rupikakapoor](https://github.com/rupikakapoor))
- Update kinesis.rb [\#553](https://github.com/fog/fog-aws/pull/553) ([ioquatix](https://github.com/ioquatix))

## [v3.6.2](https://github.com/fog/fog-aws/tree/v3.6.2) (2020-03-24)

[Full Changelog](https://github.com/fog/fog-aws/compare/v3.5.2...v3.6.2)

**Closed issues:**

- config.assets.prefix is being looked at as a bucket name [\#551](https://github.com/fog/fog-aws/issues/551)
- Class name typo: AssumeRoleWithWithWebIdentity [\#548](https://github.com/fog/fog-aws/issues/548)
- filename too long [\#544](https://github.com/fog/fog-aws/issues/544)

**Merged pull requests:**

- Adding two missing regions to Fog::AWS.regions [\#552](https://github.com/fog/fog-aws/pull/552) ([lvangool](https://github.com/lvangool))
- Adds missing param WebIdentityToken for the request to the AWS api [\#550](https://github.com/fog/fog-aws/pull/550) ([dgoradia](https://github.com/dgoradia))
- Fixes type in class name for STS assume\_role\_with\_web\_identity parser [\#549](https://github.com/fog/fog-aws/pull/549) ([dgoradia](https://github.com/dgoradia))
- Add missing AWS flavors [\#547](https://github.com/fog/fog-aws/pull/547) ([ybart](https://github.com/ybart))
- Update elasticache mocking regions [\#545](https://github.com/fog/fog-aws/pull/545) ([yads](https://github.com/yads))
- Feature/elbv2 creation endpoint [\#542](https://github.com/fog/fog-aws/pull/542) ([KevinLoiseau](https://github.com/KevinLoiseau))
- Fix/sd 8581/retrieve provider snapshot status from provider [\#541](https://github.com/fog/fog-aws/pull/541) ([toubs13](https://github.com/toubs13))
- Fix/missing implementation in listener parser [\#540](https://github.com/fog/fog-aws/pull/540) ([KevinLoiseau](https://github.com/KevinLoiseau))
- Enhance/elbv2 tag endpoints [\#539](https://github.com/fog/fog-aws/pull/539) ([KevinLoiseau](https://github.com/KevinLoiseau))
- Improve documentation and development setup [\#538](https://github.com/fog/fog-aws/pull/538) ([gustavosobral](https://github.com/gustavosobral))
- Add object tagging [\#537](https://github.com/fog/fog-aws/pull/537) ([gustavosobral](https://github.com/gustavosobral))
- Fix load balancers parser to handle more than one availability zone with addresses [\#536](https://github.com/fog/fog-aws/pull/536) ([KevinLoiseau](https://github.com/KevinLoiseau))
- Remove useless attribute location from directory model [\#535](https://github.com/fog/fog-aws/pull/535) ([KevinLoiseau](https://github.com/KevinLoiseau))
- Create service ELBV2 to handle specificities of 2015-12-01 API version [\#534](https://github.com/fog/fog-aws/pull/534) ([KevinLoiseau](https://github.com/KevinLoiseau))
- Add missing m5a flavors [\#533](https://github.com/fog/fog-aws/pull/533) ([ybart](https://github.com/ybart))
- Enhance/add some attributes to hosted zone parsers [\#531](https://github.com/fog/fog-aws/pull/531) ([KevinLoiseau](https://github.com/KevinLoiseau))
- Fix VPC tenancy on creation [\#530](https://github.com/fog/fog-aws/pull/530) ([ramonpm](https://github.com/ramonpm))
- Fix subnet's parsings [\#529](https://github.com/fog/fog-aws/pull/529) ([KevinLoiseau](https://github.com/KevinLoiseau))

## [v3.5.2](https://github.com/fog/fog-aws/tree/v3.5.2) (2019-07-16)

[Full Changelog](https://github.com/fog/fog-aws/compare/v3.5.1...v3.5.2)

**Closed issues:**

- Support for Hong Kong Region \(ap-east-1\)? [\#527](https://github.com/fog/fog-aws/issues/527)
- Make S3 Signature v4 Streaming Optional [\#523](https://github.com/fog/fog-aws/issues/523)

**Merged pull requests:**

- Add ap-east-1 \(Hong Kong\) to Fog::AWS.regions [\#528](https://github.com/fog/fog-aws/pull/528) ([tisba](https://github.com/tisba))
- Update shared\_mock\_methods.rb [\#526](https://github.com/fog/fog-aws/pull/526) ([MiWieczo](https://github.com/MiWieczo))
- Make S3 Signature v4 streaming optional [\#525](https://github.com/fog/fog-aws/pull/525) ([stanhu](https://github.com/stanhu))

## [v3.5.1](https://github.com/fog/fog-aws/tree/v3.5.1) (2019-06-10)

[Full Changelog](https://github.com/fog/fog-aws/compare/v3.5.0...v3.5.1)

**Merged pull requests:**

- Fixed issue with InvocationType header for AWS Lambda [\#524](https://github.com/fog/fog-aws/pull/524) ([GarrisonD](https://github.com/GarrisonD))
- Add support for generating tree hash tests by adding unaligned parts. [\#521](https://github.com/fog/fog-aws/pull/521) ([hkmaly](https://github.com/hkmaly))

## [v3.5.0](https://github.com/fog/fog-aws/tree/v3.5.0) (2019-04-25)

[Full Changelog](https://github.com/fog/fog-aws/compare/v3.4.0...v3.5.0)

**Closed issues:**

- Missing AWS region: EU \(Stockholm\) eu-north-1 [\#514](https://github.com/fog/fog-aws/issues/514)
- Support for AWS fargate [\#510](https://github.com/fog/fog-aws/issues/510)

**Merged pull requests:**

- Add AWS Stockholm region [\#515](https://github.com/fog/fog-aws/pull/515) ([fred-secludit](https://github.com/fred-secludit))
- Enhance/handle ELBv2 api version [\#512](https://github.com/fog/fog-aws/pull/512) ([KevinLoiseau](https://github.com/KevinLoiseau))
- Enhance/add attribute db subnet group for db instance [\#511](https://github.com/fog/fog-aws/pull/511) ([KevinLoiseau](https://github.com/KevinLoiseau))

## [v3.4.0](https://github.com/fog/fog-aws/tree/v3.4.0) (2019-03-11)

[Full Changelog](https://github.com/fog/fog-aws/compare/v3.3.0...v3.4.0)

**Closed issues:**

- Warning: possibly useless use of == in void context [\#498](https://github.com/fog/fog-aws/issues/498)
- Cluster.ready? returns false  [\#496](https://github.com/fog/fog-aws/issues/496)
- With out AWS access key & secrect AWS services not working\(IAM Role associated\) [\#495](https://github.com/fog/fog-aws/issues/495)
- "AWS::STS | assume role with web identity \(aws\)" interferes with "Fog::Compute\[:iam\] | roles \(aws, iam\)" [\#491](https://github.com/fog/fog-aws/issues/491)
- Access S3 using a proxy [\#486](https://github.com/fog/fog-aws/issues/486)
- Warning that doesn't make sense [\#479](https://github.com/fog/fog-aws/issues/479)
- Undefined method `change\_resource\_record\_sets\_data' for Fog::AWS:Module called from fog/aws/requests/dns/change\_resource\_record\_sets.rb when attempting to modify a DNS record. [\#477](https://github.com/fog/fog-aws/issues/477)
- Is DescribeImageAttribute support missing? [\#473](https://github.com/fog/fog-aws/issues/473)
- How to fix deprecation warning: "The format Fog::CDN::AWS is deprecated" [\#466](https://github.com/fog/fog-aws/issues/466)
- Test suite failures in "Fog::Compute\[:iam\] | roles" [\#296](https://github.com/fog/fog-aws/issues/296)
- Support Amazon S3 Transfer Acceleration [\#250](https://github.com/fog/fog-aws/issues/250)
- Creating VPC instances in AWS [\#116](https://github.com/fog/fog-aws/issues/116)

**Merged pull requests:**

- Avoid using bucket\_name.host if host is overriden. [\#507](https://github.com/fog/fog-aws/pull/507) ([deepfryed](https://github.com/deepfryed))
- Fix some requests when S3 acceleration is enabled [\#506](https://github.com/fog/fog-aws/pull/506) ([NARKOZ](https://github.com/NARKOZ))
- Add support for S3 transfer acceleration [\#505](https://github.com/fog/fog-aws/pull/505) ([NARKOZ](https://github.com/NARKOZ))
- Correct DynamoDB update\_item method [\#503](https://github.com/fog/fog-aws/pull/503) ([postmodern](https://github.com/postmodern))
- Add MaxResults filter to describe security groups [\#502](https://github.com/fog/fog-aws/pull/502) ([KevinLoiseau](https://github.com/KevinLoiseau))
- Fix for Aurora Server Provisioning. [\#501](https://github.com/fog/fog-aws/pull/501) ([lockstone](https://github.com/lockstone))
- Fixes/fog/aws/rds/ready [\#497](https://github.com/fog/fog-aws/pull/497) ([villemuittari](https://github.com/villemuittari))
- Feature/adding modify instance placement [\#494](https://github.com/fog/fog-aws/pull/494) ([loperaja](https://github.com/loperaja))
- Add AMD CPU instance types [\#493](https://github.com/fog/fog-aws/pull/493) ([jfuechsl](https://github.com/jfuechsl))
- Update documentation for x-amz headers [\#492](https://github.com/fog/fog-aws/pull/492) ([knapo](https://github.com/knapo))
- Add missing generation 5 compute instance flavors [\#490](https://github.com/fog/fog-aws/pull/490) ([jfuechsl](https://github.com/jfuechsl))
- Add ability to force delete a bucket with objects [\#488](https://github.com/fog/fog-aws/pull/488) ([ramonpm](https://github.com/ramonpm))
- Modernize various tests to Ruby 2.x syntax [\#485](https://github.com/fog/fog-aws/pull/485) ([teancom](https://github.com/teancom))
- EYPP-6850 add m4.16xlarge flavor [\#480](https://github.com/fog/fog-aws/pull/480) ([thorn](https://github.com/thorn))
- pull request in attempt at fix for undefined method issue mentioned in fog/fog-aws\#477 [\#478](https://github.com/fog/fog-aws/pull/478) ([klarrimore](https://github.com/klarrimore))
- Changes to add describe\_image\_attribute support [\#476](https://github.com/fog/fog-aws/pull/476) ([keithjpaulson](https://github.com/keithjpaulson))
- add tags for describe address  [\#474](https://github.com/fog/fog-aws/pull/474) ([toubs13](https://github.com/toubs13))

## [v3.3.0](https://github.com/fog/fog-aws/tree/v3.3.0) (2018-09-18)

[Full Changelog](https://github.com/fog/fog-aws/compare/v3.2.0...v3.3.0)

**Merged pull requests:**

- Rename CDN::AWS to AWS::CDN [\#467](https://github.com/fog/fog-aws/pull/467) ([jaredbeck](https://github.com/jaredbeck))

## [v3.2.0](https://github.com/fog/fog-aws/tree/v3.2.0) (2018-09-17)

[Full Changelog](https://github.com/fog/fog-aws/compare/v3.1.0...v3.2.0)

**Merged pull requests:**

- Rename Storage::AWS to AWS::Storage [\#470](https://github.com/fog/fog-aws/pull/470) ([sue445](https://github.com/sue445))
- Rename DNS::AWS to AWS::DNS [\#469](https://github.com/fog/fog-aws/pull/469) ([sue445](https://github.com/sue445))
- Rename Compute::AWS to AWS::Compute [\#468](https://github.com/fog/fog-aws/pull/468) ([sue445](https://github.com/sue445))

## [v3.1.0](https://github.com/fog/fog-aws/tree/v3.1.0) (2018-09-17)

[Full Changelog](https://github.com/fog/fog-aws/compare/v3.0.0...v3.1.0)

**Closed issues:**

- Option to disable ssl verification [\#465](https://github.com/fog/fog-aws/issues/465)
- s3: fog returns bad URL \(with correct signature\) [\#462](https://github.com/fog/fog-aws/issues/462)
- Getting permanent link without X-Amz-Expires=600 [\#459](https://github.com/fog/fog-aws/issues/459)
- add region cn-northwest-1 [\#455](https://github.com/fog/fog-aws/issues/455)
- Parameterize "RequestLimitExceeded" jitter magnitude [\#448](https://github.com/fog/fog-aws/issues/448)
- Release new version to RubyGems [\#442](https://github.com/fog/fog-aws/issues/442)
- Fog::Compute::AWS::Vpcs returns VPCs with nil ids [\#387](https://github.com/fog/fog-aws/issues/387)

**Merged pull requests:**

- Escape / in presigned URLs [\#463](https://github.com/fog/fog-aws/pull/463) ([alexcern](https://github.com/alexcern))
- Fix t1.micro bits [\#460](https://github.com/fog/fog-aws/pull/460) ([tas50](https://github.com/tas50))
- Storage region support for cn-northwest-1 [\#458](https://github.com/fog/fog-aws/pull/458) ([deepfryed](https://github.com/deepfryed))
- Simplify constructor [\#457](https://github.com/fog/fog-aws/pull/457) ([lvangool](https://github.com/lvangool))
- Add missing attribute to RDS server [\#456](https://github.com/fog/fog-aws/pull/456) ([brianknight10](https://github.com/brianknight10))
- Fix & update aws flavor \(provided in GiB\) to Megabytes \(floor rounded\). [\#454](https://github.com/fog/fog-aws/pull/454) ([xward](https://github.com/xward))
- Update aws flavors cpu count for gpu oriented flavor. [\#453](https://github.com/fog/fog-aws/pull/453) ([xward](https://github.com/xward))
- Update aws flavors cpu count. [\#452](https://github.com/fog/fog-aws/pull/452) ([xward](https://github.com/xward))
- Parameterized retry [\#451](https://github.com/fog/fog-aws/pull/451) ([lvangool](https://github.com/lvangool))
- Fix c1.xlarge cpu count [\#449](https://github.com/fog/fog-aws/pull/449) ([romaintb](https://github.com/romaintb))
- Retry if  instance not found when adding EC2 tags [\#446](https://github.com/fog/fog-aws/pull/446) ([tracemeyers](https://github.com/tracemeyers))
- Support new Paris and AP Osaka load balancers in DNS [\#445](https://github.com/fog/fog-aws/pull/445) ([mattheworiordan](https://github.com/mattheworiordan))
- Docs: Update changelog for 3.0.0 [\#444](https://github.com/fog/fog-aws/pull/444) ([jaredbeck](https://github.com/jaredbeck))
- Add encryption to EFS FileSystem creation [\#438](https://github.com/fog/fog-aws/pull/438) ([acant](https://github.com/acant))
- SetInstanceProtection endpoint for auto scaling groups support [\#436](https://github.com/fog/fog-aws/pull/436) ([thorn](https://github.com/thorn))

## [v3.0.0](https://github.com/fog/fog-aws/tree/v3.0.0) (2018-04-23)

[Full Changelog](https://github.com/fog/fog-aws/compare/v2.0.1...v3.0.0)

**Closed issues:**

- Easily Delete S3 directory and it contents? [\#435](https://github.com/fog/fog-aws/issues/435)
- S3 upload help -- likely user error :\) [\#432](https://github.com/fog/fog-aws/issues/432)
- Fog not work without pry [\#317](https://github.com/fog/fog-aws/issues/317)

**Merged pull requests:**

- fix: attach volume on \#save, remove \#server= [\#443](https://github.com/fog/fog-aws/pull/443) ([lanej](https://github.com/lanej))
- Adding g3 flavors [\#440](https://github.com/fog/fog-aws/pull/440) ([AlexLamande](https://github.com/AlexLamande))
- Add c5 and m5 instance types. [\#439](https://github.com/fog/fog-aws/pull/439) ([rogersd](https://github.com/rogersd))
- Include link to full documentation [\#434](https://github.com/fog/fog-aws/pull/434) ([kylefox](https://github.com/kylefox))
- fog-core 2.x, fog-json 1.x [\#433](https://github.com/fog/fog-aws/pull/433) ([lanej](https://github.com/lanej))

## [v2.0.1](https://github.com/fog/fog-aws/tree/v2.0.1) (2018-02-28)

[Full Changelog](https://github.com/fog/fog-aws/compare/v2.0.0...v2.0.1)

**Closed issues:**

- Unable to use fog-aws with DigitalOcean Spaces: MissingContentLength [\#428](https://github.com/fog/fog-aws/issues/428)
- Add new France region [\#424](https://github.com/fog/fog-aws/issues/424)
- How to set root volume size with bootstrap method? [\#417](https://github.com/fog/fog-aws/issues/417)
- Update Dependencies [\#227](https://github.com/fog/fog-aws/issues/227)

**Merged pull requests:**

- Expose S3 pre-signed object delete url [\#431](https://github.com/fog/fog-aws/pull/431) ([nolith](https://github.com/nolith))
- Fronzen strings fix [\#430](https://github.com/fog/fog-aws/pull/430) ([zhulik](https://github.com/zhulik))
- Expose elastic ip's private\_ip\_address [\#427](https://github.com/fog/fog-aws/pull/427) ([KevinLoiseau](https://github.com/KevinLoiseau))
- add france \(eu-west-3\) new region, fix \#424 [\#425](https://github.com/fog/fog-aws/pull/425) ([Val](https://github.com/Val))

## [v2.0.0](https://github.com/fog/fog-aws/tree/v2.0.0) (2017-11-28)

[Full Changelog](https://github.com/fog/fog-aws/compare/v1.4.1...v2.0.0)

**Closed issues:**

- connect\_write timeout on AWS CodeBuild [\#413](https://github.com/fog/fog-aws/issues/413)
- cannot load such file -- fog \(LoadError\) [\#401](https://github.com/fog/fog-aws/issues/401)
- Missing file for extraction? [\#390](https://github.com/fog/fog-aws/issues/390)
-  Regression: IO stream sent to AWS fails [\#388](https://github.com/fog/fog-aws/issues/388)
- Stack Level Too Deep on YAML Serialization [\#385](https://github.com/fog/fog-aws/issues/385)
- models/elb/model\_tests does not properly cleanup [\#347](https://github.com/fog/fog-aws/issues/347)
- Generates wrong url when region is not DEFAULT\_REGION [\#214](https://github.com/fog/fog-aws/issues/214)

**Merged pull requests:**

- upgrade rubyzip to \>= 1.2.1 [\#416](https://github.com/fog/fog-aws/pull/416) ([lanej](https://github.com/lanej))
- correction in iam/list\_access\_keys parser: Username should be UserName [\#415](https://github.com/fog/fog-aws/pull/415) ([patleb](https://github.com/patleb))
- Avoid creating connection if region is not nil [\#414](https://github.com/fog/fog-aws/pull/414) ([hideto0710](https://github.com/hideto0710))
- Resolving issue where `Fog::Json` was called instead of `Fog::JSON`. [\#412](https://github.com/fog/fog-aws/pull/412) ([mgarrick](https://github.com/mgarrick))
- Add t2.micro in flavors list [\#411](https://github.com/fog/fog-aws/pull/411) ([KevinLoiseau](https://github.com/KevinLoiseau))
- Adding AWS P3 Tesla GPU instance types [\#409](https://github.com/fog/fog-aws/pull/409) ([hamelsmu](https://github.com/hamelsmu))
- Add jitter to exponential backoff [\#408](https://github.com/fog/fog-aws/pull/408) ([masstamike](https://github.com/masstamike))
- Add emulation of default VPC to mocked mode. [\#407](https://github.com/fog/fog-aws/pull/407) ([rzaharenkov](https://github.com/rzaharenkov))
- Update rds instance options model [\#406](https://github.com/fog/fog-aws/pull/406) ([carloslima](https://github.com/carloslima))
- Drop Ruby\<2.0 support [\#405](https://github.com/fog/fog-aws/pull/405) ([tbrisker](https://github.com/tbrisker))
- allow Gemfile-edge travis builds to fail [\#403](https://github.com/fog/fog-aws/pull/403) ([lanej](https://github.com/lanej))
- Add `default_for_az` attribute to subnet [\#402](https://github.com/fog/fog-aws/pull/402) ([rzaharenkov](https://github.com/rzaharenkov))
- bundler ~\> 1.15 [\#399](https://github.com/fog/fog-aws/pull/399) ([lanej](https://github.com/lanej))
- Fix detaching instances from auto scaling group. [\#397](https://github.com/fog/fog-aws/pull/397) ([rzaharenkov](https://github.com/rzaharenkov))
- Issue \#387 Fog::Compute::AWS::Vpcs returns VPCs with nil ids [\#396](https://github.com/fog/fog-aws/pull/396) ([maguec](https://github.com/maguec))
- feat\(CONTRIBUTORS\): Update [\#394](https://github.com/fog/fog-aws/pull/394) ([plribeiro3000](https://github.com/plribeiro3000))
- fix\(Tests\):Remove debugging [\#393](https://github.com/fog/fog-aws/pull/393) ([plribeiro3000](https://github.com/plribeiro3000))
- Migrate Service mapper from Fog [\#392](https://github.com/fog/fog-aws/pull/392) ([plribeiro3000](https://github.com/plribeiro3000))
- Add ability to encrypt a copy of an unencrypted snapshot [\#391](https://github.com/fog/fog-aws/pull/391) ([nodecarter](https://github.com/nodecarter))
- Fix VPC parser [\#389](https://github.com/fog/fog-aws/pull/389) ([ddiachkov](https://github.com/ddiachkov))
- fix default\_security\_group detection [\#348](https://github.com/fog/fog-aws/pull/348) ([lanej](https://github.com/lanej))

## [v1.4.1](https://github.com/fog/fog-aws/tree/v1.4.1) (2017-08-23)

[Full Changelog](https://github.com/fog/fog-aws/compare/v1.4.0...v1.4.1)

**Closed issues:**

- retrieval of ipv6 vpc  [\#379](https://github.com/fog/fog-aws/issues/379)
- Timeout when trying to bootstrap or ssh spot request instances [\#372](https://github.com/fog/fog-aws/issues/372)
- Why default VPC does not require Elastic IP to connect in internet [\#338](https://github.com/fog/fog-aws/issues/338)
- Chunked images response causing Nokogiri::XML::SyntaxError [\#273](https://github.com/fog/fog-aws/issues/273)

**Merged pull requests:**

- Update changelog for 1.4.0 [\#383](https://github.com/fog/fog-aws/pull/383) ([greysteil](https://github.com/greysteil))
- Allow specifying kms key id to use [\#382](https://github.com/fog/fog-aws/pull/382) ([fcheung](https://github.com/fcheung))
- added support to retrieve and create vpc with ipv6 cidr block [\#381](https://github.com/fog/fog-aws/pull/381) ([chanakyacool](https://github.com/chanakyacool))
- Add MaxResults filter to describe reserved instances offerings [\#376](https://github.com/fog/fog-aws/pull/376) ([KevinLoiseau](https://github.com/KevinLoiseau))
- Fix Fog::Compute::AWS::Images\#all [\#375](https://github.com/fog/fog-aws/pull/375) ([eddiej](https://github.com/eddiej))
- Fix AWS credential mocking [\#374](https://github.com/fog/fog-aws/pull/374) ([v-yarotsky](https://github.com/v-yarotsky))

## [v1.4.0](https://github.com/fog/fog-aws/tree/v1.4.0) (2017-06-14)

[Full Changelog](https://github.com/fog/fog-aws/compare/v1.3.0...v1.4.0)

**Closed issues:**

- Support REST Bucket Get v2 [\#369](https://github.com/fog/fog-aws/issues/369)
- Fog::AWS::IAM::Error: InvalidAction =\> Could not find operation "ReplaceIamInstanceProfileAssociation" for version 2010-05-08 [\#368](https://github.com/fog/fog-aws/issues/368)
- Multipart upload fails on empty files [\#364](https://github.com/fog/fog-aws/issues/364)
- The action `ModifyVolume` is not valid for this web service. [\#363](https://github.com/fog/fog-aws/issues/363)
- Cache/read local amazon data [\#354](https://github.com/fog/fog-aws/issues/354)

**Merged pull requests:**

- add NextContinuationToken support to GetBucket operation [\#370](https://github.com/fog/fog-aws/pull/370) ([khoan](https://github.com/khoan))
- Add a top-level require that matches the gem name [\#367](https://github.com/fog/fog-aws/pull/367) ([lanej](https://github.com/lanej))
- Fixed credential refresh when instance metadata host is inaccessible [\#366](https://github.com/fog/fog-aws/pull/366) ([ankane](https://github.com/ankane))
- Handle multipart upload of empty files [\#365](https://github.com/fog/fog-aws/pull/365) ([fcheung](https://github.com/fcheung))
- Add p2 instance types [\#362](https://github.com/fog/fog-aws/pull/362) ([caged](https://github.com/caged))
- Exponential backoff [\#361](https://github.com/fog/fog-aws/pull/361) ([VVMichaelSawyer](https://github.com/VVMichaelSawyer))
- Skip call to instance metadata host if region is specified [\#360](https://github.com/fog/fog-aws/pull/360) ([ankane](https://github.com/ankane))

## [v1.3.0](https://github.com/fog/fog-aws/tree/v1.3.0) (2017-03-29)

[Full Changelog](https://github.com/fog/fog-aws/compare/v1.2.1...v1.3.0)

**Closed issues:**

- Do we need to list all files before creating one? [\#357](https://github.com/fog/fog-aws/issues/357)

**Merged pull requests:**

- Authorize vpc to rds sg [\#356](https://github.com/fog/fog-aws/pull/356) ([ehowe](https://github.com/ehowe))
- classic link enhancements [\#355](https://github.com/fog/fog-aws/pull/355) ([ehowe](https://github.com/ehowe))
- Add new i3 class instances. [\#353](https://github.com/fog/fog-aws/pull/353) ([rogersd](https://github.com/rogersd))
- Add check for self.etag before running gsub [\#351](https://github.com/fog/fog-aws/pull/351) ([dmcorboy](https://github.com/dmcorboy))
- Modify volume [\#350](https://github.com/fog/fog-aws/pull/350) ([ehowe](https://github.com/ehowe))

## [v1.2.1](https://github.com/fog/fog-aws/tree/v1.2.1) (2017-02-27)

[Full Changelog](https://github.com/fog/fog-aws/compare/v1.2.0...v1.2.1)

**Closed issues:**

- Fog mock does not mimmick real behaviour for some Excon errors [\#341](https://github.com/fog/fog-aws/issues/341)

**Merged pull requests:**

- Spot fixes [\#349](https://github.com/fog/fog-aws/pull/349) ([ehowe](https://github.com/ehowe))
- add natGatewayId to describe\_route\_tables [\#346](https://github.com/fog/fog-aws/pull/346) ([mliao2](https://github.com/mliao2))
- Fog mock accuracy, fixes \#341 [\#344](https://github.com/fog/fog-aws/pull/344) ([easkay](https://github.com/easkay))
- Subnet [\#343](https://github.com/fog/fog-aws/pull/343) ([ehowe](https://github.com/ehowe))
- Fix multipart upload [\#340](https://github.com/fog/fog-aws/pull/340) ([nobmurakita](https://github.com/nobmurakita))

## [v1.2.0](https://github.com/fog/fog-aws/tree/v1.2.0) (2017-01-20)

[Full Changelog](https://github.com/fog/fog-aws/compare/v1.1.0...v1.2.0)

**Closed issues:**

- Support for AWS Application Load Balancer \(ALB\) [\#335](https://github.com/fog/fog-aws/issues/335)

**Merged pull requests:**

- Better iam policies [\#339](https://github.com/fog/fog-aws/pull/339) ([ehowe](https://github.com/ehowe))
- Pin nokogiri gem for Ruby 1.9 and Ruby 2.0 [\#337](https://github.com/fog/fog-aws/pull/337) ([sodabrew](https://github.com/sodabrew))
- Fix parsing of the Reserved Instance 'recurringCharge' field and add 'scope' field [\#336](https://github.com/fog/fog-aws/pull/336) ([sodabrew](https://github.com/sodabrew))
- Fixes / improvements for AutoScaling [\#334](https://github.com/fog/fog-aws/pull/334) ([lanej](https://github.com/lanej))

## [v1.1.0](https://github.com/fog/fog-aws/tree/v1.1.0) (2016-12-16)

[Full Changelog](https://github.com/fog/fog-aws/compare/v1.0.0...v1.1.0)

**Closed issues:**

- Support new Ohio region \(us-east-2\) [\#313](https://github.com/fog/fog-aws/issues/313)

**Merged pull requests:**

- Canada and London regions [\#333](https://github.com/fog/fog-aws/pull/333) ([mattheworiordan](https://github.com/mattheworiordan))
- Updated ELB Dual Stack hosted zone DNS records [\#332](https://github.com/fog/fog-aws/pull/332) ([mattheworiordan](https://github.com/mattheworiordan))
- Added support for attaching auto scaling groups to target groups [\#330](https://github.com/fog/fog-aws/pull/330) ([maf23](https://github.com/maf23))
- credential\_fetcher: Mark AWS metadata calls as idempotent [\#329](https://github.com/fog/fog-aws/pull/329) ([mtekel](https://github.com/mtekel))

## [v1.0.0](https://github.com/fog/fog-aws/tree/v1.0.0) (2016-12-12)

[Full Changelog](https://github.com/fog/fog-aws/compare/v0.13.0...v1.0.0)

**Merged pull requests:**

- fix host header with another port on s3 [\#327](https://github.com/fog/fog-aws/pull/327) ([rodrigoapereira](https://github.com/rodrigoapereira))
- Add new t2.xlarge, t2.2xlarge and r4 class instances. [\#326](https://github.com/fog/fog-aws/pull/326) ([rogersd](https://github.com/rogersd))
- Fix the bug that can't create fifo queue in SQS. [\#323](https://github.com/fog/fog-aws/pull/323) ([ebihara99999](https://github.com/ebihara99999))
- data pipeline mocks [\#318](https://github.com/fog/fog-aws/pull/318) ([ehowe](https://github.com/ehowe))

## [v0.13.0](https://github.com/fog/fog-aws/tree/v0.13.0) (2016-11-29)

[Full Changelog](https://github.com/fog/fog-aws/compare/v0.12.0...v0.13.0)

**Closed issues:**

- Fog::Compute::AWS::Image not properly loaded [\#324](https://github.com/fog/fog-aws/issues/324)
- Add creation\_date field for aws images [\#320](https://github.com/fog/fog-aws/issues/320)
- Bug: \[fog\]\[WARNING\] Unrecognized arguments: region, use\_iam\_profile [\#315](https://github.com/fog/fog-aws/issues/315)
- Better contributing documentation [\#311](https://github.com/fog/fog-aws/issues/311)
- AutoscalingGroups with a TargetGroup set are not parsed correctly [\#308](https://github.com/fog/fog-aws/issues/308)
- autoscaling create launch config doesn't work with BlockDeviceMappings  [\#307](https://github.com/fog/fog-aws/issues/307)
- Is there a configuration setting for the AWS provider to adjust the url scheme for S3 buckets? [\#305](https://github.com/fog/fog-aws/issues/305)
- DB Subnet Group id for Cluster returns nil [\#292](https://github.com/fog/fog-aws/issues/292)

**Merged pull requests:**

- Fixed some missing parts in change sets [\#322](https://github.com/fog/fog-aws/pull/322) ([nilroy](https://github.com/nilroy))
- Add creation date and enhanced networking support for images [\#321](https://github.com/fog/fog-aws/pull/321) ([puneetloya](https://github.com/puneetloya))
- Fix warnings in running tests [\#319](https://github.com/fog/fog-aws/pull/319) ([ebihara99999](https://github.com/ebihara99999))
- Add `Fog::AWS::STS.Mock#assume_role` [\#316](https://github.com/fog/fog-aws/pull/316) ([pedrommonteiro](https://github.com/pedrommonteiro))
- Ohio region [\#314](https://github.com/fog/fog-aws/pull/314) ([chanakyacool](https://github.com/chanakyacool))
- mime types gem update [\#312](https://github.com/fog/fog-aws/pull/312) ([lucianosousa](https://github.com/lucianosousa))
- fix S3 \#delete\_multiple\_objects for UTF-8 names [\#310](https://github.com/fog/fog-aws/pull/310) ([alepore](https://github.com/alepore))
- Support for target groups \(fix for \#308\) [\#309](https://github.com/fog/fog-aws/pull/309) ([msiuts](https://github.com/msiuts))
- create, describe, and destroy elastic file systems [\#304](https://github.com/fog/fog-aws/pull/304) ([ehowe](https://github.com/ehowe))
- Correct optional parameter naming in documentation for Fog::AWS::Auto… [\#302](https://github.com/fog/fog-aws/pull/302) ([ehealy](https://github.com/ehealy))
- Modify Db subnet group  [\#293](https://github.com/fog/fog-aws/pull/293) ([chanakyacool](https://github.com/chanakyacool))

## [v0.12.0](https://github.com/fog/fog-aws/tree/v0.12.0) (2016-09-22)

[Full Changelog](https://github.com/fog/fog-aws/compare/v0.11.0...v0.12.0)

**Implemented enhancements:**

- Add gestion of egress security group rules [\#290](https://github.com/fog/fog-aws/pull/290) ([KevinLoiseau](https://github.com/KevinLoiseau))

**Closed issues:**

- Fog directory appends local system path with amazon url when i try to give dynamic fog directory [\#295](https://github.com/fog/fog-aws/issues/295)
- Getting OperationAborted error on file storage operation [\#288](https://github.com/fog/fog-aws/issues/288)
- AWS Elasticsearch API [\#286](https://github.com/fog/fog-aws/issues/286)
- Disable chunked encoding [\#285](https://github.com/fog/fog-aws/issues/285)

**Merged pull requests:**

- add support endpoint and models/requests for trusted advisor checks [\#300](https://github.com/fog/fog-aws/pull/300) ([ehowe](https://github.com/ehowe))
- Add attribute is\_default in vpc [\#299](https://github.com/fog/fog-aws/pull/299) ([zhitongLBN](https://github.com/zhitongLBN))
- Cloud Formation: additional parameters [\#298](https://github.com/fog/fog-aws/pull/298) ([neillturner](https://github.com/neillturner))
- Cloud Formation: support for change sets, stack policy and other missing calls.   [\#297](https://github.com/fog/fog-aws/pull/297) ([neillturner](https://github.com/neillturner))

## [v0.11.0](https://github.com/fog/fog-aws/tree/v0.11.0) (2016-08-04)

[Full Changelog](https://github.com/fog/fog-aws/compare/v0.10.0...v0.11.0)

**Merged pull requests:**

- GitHub does no longer provide http:// pages [\#284](https://github.com/fog/fog-aws/pull/284) ([amatsuda](https://github.com/amatsuda))
- Skip multipart if body size is less than chunk.  [\#283](https://github.com/fog/fog-aws/pull/283) ([brettcave](https://github.com/brettcave))
- ECS container credentials [\#281](https://github.com/fog/fog-aws/pull/281) ([ryansch](https://github.com/ryansch))
- test\(ci\): fix 1.9 builds with json \>= 2.0 [\#280](https://github.com/fog/fog-aws/pull/280) ([lanej](https://github.com/lanej))
- Change DBSubnetGroup to DBSubnetGroupName model cluster while creation [\#279](https://github.com/fog/fog-aws/pull/279) ([chanakyacool](https://github.com/chanakyacool))

## [v0.10.0](https://github.com/fog/fog-aws/tree/v0.10.0) (2016-07-15)

[Full Changelog](https://github.com/fog/fog-aws/compare/v0.9.4...v0.10.0)

**Closed issues:**

- How to setup private files with CloudFront? [\#275](https://github.com/fog/fog-aws/issues/275)
- Feature: Custom Managed Policies [\#272](https://github.com/fog/fog-aws/issues/272)
- Support an IAM list\_attached\_role\_policies method [\#191](https://github.com/fog/fog-aws/issues/191)

**Merged pull requests:**

- RDS test fixes [\#276](https://github.com/fog/fog-aws/pull/276) ([MrPrimate](https://github.com/MrPrimate))
- Expanding IAM support [\#274](https://github.com/fog/fog-aws/pull/274) ([MrPrimate](https://github.com/MrPrimate))
- Rds snapshot improvements [\#269](https://github.com/fog/fog-aws/pull/269) ([tekken](https://github.com/tekken))
- add default region to use\_iam\_profile [\#268](https://github.com/fog/fog-aws/pull/268) ([shaiguitar](https://github.com/shaiguitar))

## [v0.9.4](https://github.com/fog/fog-aws/tree/v0.9.4) (2016-06-28)

[Full Changelog](https://github.com/fog/fog-aws/compare/v0.9.3...v0.9.4)

**Closed issues:**

- S3: retry on 503 Service Unavailable [\#265](https://github.com/fog/fog-aws/issues/265)
- Digest::Base Error [\#261](https://github.com/fog/fog-aws/issues/261)

**Merged pull requests:**

- Updated Region 'Mumbai' ap-south-1  [\#267](https://github.com/fog/fog-aws/pull/267) ([chanakyacool](https://github.com/chanakyacool))
- Replaces usage of Digest with OpenSSL::Digest  [\#266](https://github.com/fog/fog-aws/pull/266) ([esthervillars](https://github.com/esthervillars))
- AWS DNS - support newer DNS hosted zone IDs for dualstack ELBs [\#263](https://github.com/fog/fog-aws/pull/263) ([mattheworiordan](https://github.com/mattheworiordan))

## [v0.9.3](https://github.com/fog/fog-aws/tree/v0.9.3) (2016-06-20)

[Full Changelog](https://github.com/fog/fog-aws/compare/v0.9.2...v0.9.3)

**Closed issues:**

- Users list is empty in Fog::AWS::IAM::Groups  [\#256](https://github.com/fog/fog-aws/issues/256)
- I'd like to configure my Excon read\_timeout and write\_timeout  [\#254](https://github.com/fog/fog-aws/issues/254)
- Bump fog-core to \>=1.38.0 [\#247](https://github.com/fog/fog-aws/issues/247)
- no implicit conversion of Array into String in `aws/storage.rb` from `bucket_name` in params. [\#246](https://github.com/fog/fog-aws/issues/246)
- \[S3\] Bucket name gets duplicated in case of redirect from AWS [\#242](https://github.com/fog/fog-aws/issues/242)
- CloudFormation stack tags cause describe\_stacks to break [\#240](https://github.com/fog/fog-aws/issues/240)

**Merged pull requests:**

- Parse EbsOptimized parameter in launch configuration description [\#259](https://github.com/fog/fog-aws/pull/259) ([djudd](https://github.com/djudd))
- Allow case-insensitive record comparison [\#258](https://github.com/fog/fog-aws/pull/258) ([matthewpick](https://github.com/matthewpick))
- Fix for empty ETag values [\#257](https://github.com/fog/fog-aws/pull/257) ([baryshev](https://github.com/baryshev))
- do not make requests if mocked. [\#252](https://github.com/fog/fog-aws/pull/252) ([shaiguitar](https://github.com/shaiguitar))
- Parse CloudWatch alarm actions as arrays instead of strings [\#245](https://github.com/fog/fog-aws/pull/245) ([eherot](https://github.com/eherot))
- Add support for CloudFormation stack tags. [\#241](https://github.com/fog/fog-aws/pull/241) ([jamesremuscat](https://github.com/jamesremuscat))
- Add log warning message about when not on us-region [\#200](https://github.com/fog/fog-aws/pull/200) ([kitofr](https://github.com/kitofr))

## [v0.9.2](https://github.com/fog/fog-aws/tree/v0.9.2) (2016-03-23)

[Full Changelog](https://github.com/fog/fog-aws/compare/v0.9.1...v0.9.2)

**Closed issues:**

- CHANGELOG.md is out of date [\#235](https://github.com/fog/fog-aws/issues/235)

**Merged pull requests:**

- Aurora [\#238](https://github.com/fog/fog-aws/pull/238) ([ehowe](https://github.com/ehowe))

## [v0.9.1](https://github.com/fog/fog-aws/tree/v0.9.1) (2016-03-04)

[Full Changelog](https://github.com/fog/fog-aws/compare/v0.8.2...v0.9.1)

## [v0.8.2](https://github.com/fog/fog-aws/tree/v0.8.2) (2016-03-04)

[Full Changelog](https://github.com/fog/fog-aws/compare/v0.9.0...v0.8.2)

**Merged pull requests:**

- autoscaler attach/detatch [\#229](https://github.com/fog/fog-aws/pull/229) ([shaiguitar](https://github.com/shaiguitar))

## [v0.9.0](https://github.com/fog/fog-aws/tree/v0.9.0) (2016-03-03)

[Full Changelog](https://github.com/fog/fog-aws/compare/v0.8.1...v0.9.0)

**Closed issues:**

- Fog::Storage::AWS::File\#save deprecation warning without alternative [\#226](https://github.com/fog/fog-aws/issues/226)
- Long format of aws resources [\#216](https://github.com/fog/fog-aws/issues/216)

**Merged pull requests:**

- Update README.md [\#233](https://github.com/fog/fog-aws/pull/233) ([h0lyalg0rithm](https://github.com/h0lyalg0rithm))
- fix mime-types CI issues, add 2.3.0 testing [\#231](https://github.com/fog/fog-aws/pull/231) ([lanej](https://github.com/lanej))
- support for rds clusters and aurora [\#230](https://github.com/fog/fog-aws/pull/230) ([ehowe](https://github.com/ehowe))
- Correct default DescribeAvailabilityZone filter to zone-name [\#225](https://github.com/fog/fog-aws/pull/225) ([gregburek](https://github.com/gregburek))
- Security Group perms of FromPort 0 and ToPort -1 [\#223](https://github.com/fog/fog-aws/pull/223) ([jacobo](https://github.com/jacobo))
- Page default parameters [\#222](https://github.com/fog/fog-aws/pull/222) ([ehowe](https://github.com/ehowe))
- rds enhancements [\#220](https://github.com/fog/fog-aws/pull/220) ([ehowe](https://github.com/ehowe))
- Added ap-northeast-2 to the fog mocks. [\#219](https://github.com/fog/fog-aws/pull/219) ([wyhaines](https://github.com/wyhaines))
- restore db instance fom db snapshot [\#217](https://github.com/fog/fog-aws/pull/217) ([ehowe](https://github.com/ehowe))

## [v0.8.1](https://github.com/fog/fog-aws/tree/v0.8.1) (2016-01-08)

[Full Changelog](https://github.com/fog/fog-aws/compare/v0.8.0...v0.8.1)

**Merged pull requests:**

- Add new aws regions [\#213](https://github.com/fog/fog-aws/pull/213) ([atmos](https://github.com/atmos))

## [v0.8.0](https://github.com/fog/fog-aws/tree/v0.8.0) (2016-01-04)

[Full Changelog](https://github.com/fog/fog-aws/compare/v0.7.6...v0.8.0)

**Fixed bugs:**

- IAM roles.all should paginate [\#176](https://github.com/fog/fog-aws/issues/176)

**Closed issues:**

- Fog gives wrong location for buckets when connected via non-default region [\#208](https://github.com/fog/fog-aws/issues/208)
- Is there any way to skip object level `acl` setting while `public` option is true [\#207](https://github.com/fog/fog-aws/issues/207)
- using/testing on ruby 1.9 [\#203](https://github.com/fog/fog-aws/issues/203)
- S3 KMS encryption support [\#196](https://github.com/fog/fog-aws/issues/196)
- Support S3 auto-expiring files? [\#194](https://github.com/fog/fog-aws/issues/194)
- Fog::AWS::ELB::InvalidConfigurationRequest: policy cannot be enabled [\#193](https://github.com/fog/fog-aws/issues/193)
- get\_https\_url generating negative expiry [\#188](https://github.com/fog/fog-aws/issues/188)
- Streaming requests shouldn't be idempotent [\#181](https://github.com/fog/fog-aws/issues/181)
- S3 connection hangs; does Fog support timeout? [\#180](https://github.com/fog/fog-aws/issues/180)
- Doesn't work after upgrading to 0.1.2 [\#83](https://github.com/fog/fog-aws/issues/83)

**Merged pull requests:**

- When not specified, region for a bucket should be DEFAULT\_REGION. [\#211](https://github.com/fog/fog-aws/pull/211) ([jamesremuscat](https://github.com/jamesremuscat))
- Support NoncurrentVersion\[Expiration,Transition\] for s3 lifecycle. [\#210](https://github.com/fog/fog-aws/pull/210) ([xtoddx](https://github.com/xtoddx))
- Update dynamodb to use the latest API version [\#209](https://github.com/fog/fog-aws/pull/209) ([dmathieu](https://github.com/dmathieu))
- Make sure to send the KmsKeyId when creating an RDS cluster [\#206](https://github.com/fog/fog-aws/pull/206) ([drcapulet](https://github.com/drcapulet))
- Reset 'finished' when rewinding S3Streamer [\#205](https://github.com/fog/fog-aws/pull/205) ([jschneiderhan](https://github.com/jschneiderhan))
- Add mime-types to test section in Gemfile [\#204](https://github.com/fog/fog-aws/pull/204) ([kitofr](https://github.com/kitofr))
- filters on tags can pass an array [\#202](https://github.com/fog/fog-aws/pull/202) ([craiggenner](https://github.com/craiggenner))
- Document options for S3 server-side encryption [\#199](https://github.com/fog/fog-aws/pull/199) ([shuhei](https://github.com/shuhei))
- make net/ssh require optional [\#197](https://github.com/fog/fog-aws/pull/197) ([geemus](https://github.com/geemus))
- Cache cluster security group parser [\#190](https://github.com/fog/fog-aws/pull/190) ([eherot](https://github.com/eherot))
- Allow region to be set for STS [\#189](https://github.com/fog/fog-aws/pull/189) ([fcheung](https://github.com/fcheung))
- add cn support for s3 [\#187](https://github.com/fog/fog-aws/pull/187) ([ming535](https://github.com/ming535))
- mock instance stop and start properly [\#184](https://github.com/fog/fog-aws/pull/184) ([ehowe](https://github.com/ehowe))
- Disable idempotent option when block is passed to get\_object [\#183](https://github.com/fog/fog-aws/pull/183) ([ghost](https://github.com/ghost))
- Yield arguments to Mock\#get\_object block more similar to Excon [\#182](https://github.com/fog/fog-aws/pull/182) ([tdg5](https://github.com/tdg5))
- add IAM role paging [\#178](https://github.com/fog/fog-aws/pull/178) ([lanej](https://github.com/lanej))
- properly mock rds name update [\#170](https://github.com/fog/fog-aws/pull/170) ([ehowe](https://github.com/ehowe))

## [v0.7.6](https://github.com/fog/fog-aws/tree/v0.7.6) (2015-08-26)

[Full Changelog](https://github.com/fog/fog-aws/compare/v0.7.5...v0.7.6)

**Closed issues:**

- mock directories.create destroys existing directory [\#172](https://github.com/fog/fog-aws/issues/172)

**Merged pull requests:**

- Add GovCloud region name to validation set. [\#175](https://github.com/fog/fog-aws/pull/175) ([triplepoint](https://github.com/triplepoint))
- Mocked put\_bucket no longer clobbers existing bucket [\#174](https://github.com/fog/fog-aws/pull/174) ([jgr](https://github.com/jgr))

## [v0.7.5](https://github.com/fog/fog-aws/tree/v0.7.5) (2015-08-24)

[Full Changelog](https://github.com/fog/fog-aws/compare/v0.7.4...v0.7.5)

**Closed issues:**

- how to change filepath for html\_table\_reporter in reporter options [\#167](https://github.com/fog/fog-aws/issues/167)
- Access Key, etc still required for Storage access when using use\_iam\_profile [\#162](https://github.com/fog/fog-aws/issues/162)
- Support for KMS ID for EBS Volume [\#141](https://github.com/fog/fog-aws/issues/141)

**Merged pull requests:**

- validate rds server security group associations [\#173](https://github.com/fog/fog-aws/pull/173) ([lanej](https://github.com/lanej))
- format security groups when modifying db instance [\#171](https://github.com/fog/fog-aws/pull/171) ([michelleN](https://github.com/michelleN))
- standardize region validation [\#169](https://github.com/fog/fog-aws/pull/169) ([lanej](https://github.com/lanej))
- expose elb region [\#168](https://github.com/fog/fog-aws/pull/168) ([lanej](https://github.com/lanej))
- volume\#key\_id and encrypted tests [\#165](https://github.com/fog/fog-aws/pull/165) ([lanej](https://github.com/lanej))
- raise InvalidParameterCombination error [\#163](https://github.com/fog/fog-aws/pull/163) ([michelleN](https://github.com/michelleN))
- storage request bad xml schema for put bucket notification fix [\#161](https://github.com/fog/fog-aws/pull/161) ([bahchis](https://github.com/bahchis))
- Use regex instead of string matching to support redirect correctly when path\_style is set to true [\#159](https://github.com/fog/fog-aws/pull/159) ([drich10](https://github.com/drich10))
- update \#promote\_read\_replica mock [\#158](https://github.com/fog/fog-aws/pull/158) ([lanej](https://github.com/lanej))

## [v0.7.4](https://github.com/fog/fog-aws/tree/v0.7.4) (2015-07-30)

[Full Changelog](https://github.com/fog/fog-aws/compare/v0.7.3...v0.7.4)

**Fixed bugs:**

- Route53 zone listing fix and support for private hosted zones [\#154](https://github.com/fog/fog-aws/pull/154) ([solud](https://github.com/solud))

**Merged pull requests:**

- AutoScaling attach/detach ELB support + tests [\#156](https://github.com/fog/fog-aws/pull/156) ([nbfowler](https://github.com/nbfowler))

## [v0.7.3](https://github.com/fog/fog-aws/tree/v0.7.3) (2015-07-10)

[Full Changelog](https://github.com/fog/fog-aws/compare/v0.7.2...v0.7.3)

**Closed issues:**

- "Error: The specified marker is not valid" after upgrade to 0.7.0 [\#148](https://github.com/fog/fog-aws/issues/148)

**Merged pull requests:**

- encrypted storage on rds [\#153](https://github.com/fog/fog-aws/pull/153) ([ehowe](https://github.com/ehowe))

## [v0.7.2](https://github.com/fog/fog-aws/tree/v0.7.2) (2015-07-08)

[Full Changelog](https://github.com/fog/fog-aws/compare/v0.7.1...v0.7.2)

**Fixed bugs:**

- NoMethodError trying to create a new AWS Route53 entry using version 0.7.1 [\#150](https://github.com/fog/fog-aws/issues/150)

**Merged pull requests:**

- fix \#change\_resource\_record\_sets [\#151](https://github.com/fog/fog-aws/pull/151) ([lanej](https://github.com/lanej))

## [v0.7.1](https://github.com/fog/fog-aws/tree/v0.7.1) (2015-07-08)

[Full Changelog](https://github.com/fog/fog-aws/compare/v0.7.0...v0.7.1)

**Merged pull requests:**

- Fix broken xmlns in DNS requests [\#149](https://github.com/fog/fog-aws/pull/149) ([decklin](https://github.com/decklin))
- Fix blank content-encoding headers [\#147](https://github.com/fog/fog-aws/pull/147) ([fcheung](https://github.com/fcheung))

## [v0.7.0](https://github.com/fog/fog-aws/tree/v0.7.0) (2015-07-07)

[Full Changelog](https://github.com/fog/fog-aws/compare/v0.6.0...v0.7.0)

**Closed issues:**

- Add support for AWS Lambda [\#124](https://github.com/fog/fog-aws/issues/124)

**Merged pull requests:**

- Describe vpcPeeringConnectionId [\#146](https://github.com/fog/fog-aws/pull/146) ([fdr](https://github.com/fdr))
- Adds isDefault to parser for describe\_vpcs [\#144](https://github.com/fog/fog-aws/pull/144) ([gregburek](https://github.com/gregburek))
- Support kinesis [\#143](https://github.com/fog/fog-aws/pull/143) ([mikehale](https://github.com/mikehale))
- The :geo\_location attribute needs to be xml formatted before calling aws [\#142](https://github.com/fog/fog-aws/pull/142) ([carloslima](https://github.com/carloslima))
- Escape Lambda function name in request paths [\#140](https://github.com/fog/fog-aws/pull/140) ([nomadium](https://github.com/nomadium))
- list\_hosted\_zones expects that options to be hash with symbol as key [\#139](https://github.com/fog/fog-aws/pull/139) ([slashmili](https://github.com/slashmili))

## [v0.6.0](https://github.com/fog/fog-aws/tree/v0.6.0) (2015-06-23)

[Full Changelog](https://github.com/fog/fog-aws/compare/v0.5.0...v0.6.0)

**Merged pull requests:**

- Add support for AWS Lambda service [\#123](https://github.com/fog/fog-aws/pull/123) ([nomadium](https://github.com/nomadium))

## [v0.5.0](https://github.com/fog/fog-aws/tree/v0.5.0) (2015-06-17)

[Full Changelog](https://github.com/fog/fog-aws/compare/v0.4.1...v0.5.0)

**Merged pull requests:**

- add t2.large [\#137](https://github.com/fog/fog-aws/pull/137) ([lanej](https://github.com/lanej))
- Make Mock create\_vpc method arity match Real [\#135](https://github.com/fog/fog-aws/pull/135) ([fdr](https://github.com/fdr))
- Add support for EC2 Container Service [\#120](https://github.com/fog/fog-aws/pull/120) ([nomadium](https://github.com/nomadium))

## [v0.4.1](https://github.com/fog/fog-aws/tree/v0.4.1) (2015-06-15)

[Full Changelog](https://github.com/fog/fog-aws/compare/v0.4.0...v0.4.1)

**Closed issues:**

- Fog doesn't support storage\_type or gp2 for RDS? [\#129](https://github.com/fog/fog-aws/issues/129)
- Fog-aws not working with Hitachi [\#122](https://github.com/fog/fog-aws/issues/122)
- "NoMethodError: undefined method `body' for \#\<Fog::DNS::AWS::Error:0x007f6c673e1720\>" [\#112](https://github.com/fog/fog-aws/issues/112)
- Add support for EC2 Container Service \(ECS\) [\#93](https://github.com/fog/fog-aws/issues/93)

**Merged pull requests:**

- Fix attributes of flavors [\#134](https://github.com/fog/fog-aws/pull/134) ([yumminhuang](https://github.com/yumminhuang))
- Fix S3 signature v4 signing [\#133](https://github.com/fog/fog-aws/pull/133) ([fcheung](https://github.com/fcheung))
- Add New M4 Instance Type [\#132](https://github.com/fog/fog-aws/pull/132) ([yumminhuang](https://github.com/yumminhuang))
- raise correct error when exceeding address limit [\#131](https://github.com/fog/fog-aws/pull/131) ([lanej](https://github.com/lanej))
- make elb/policies collection standalone [\#128](https://github.com/fog/fog-aws/pull/128) ([lanej](https://github.com/lanej))
- model managed policies [\#126](https://github.com/fog/fog-aws/pull/126) ([lanej](https://github.com/lanej))

## [v0.4.0](https://github.com/fog/fog-aws/tree/v0.4.0) (2015-05-27)

[Full Changelog](https://github.com/fog/fog-aws/compare/v0.3.0...v0.4.0)

**Merged pull requests:**

- model iam groups [\#121](https://github.com/fog/fog-aws/pull/121) ([lanej](https://github.com/lanej))

## [v0.3.0](https://github.com/fog/fog-aws/tree/v0.3.0) (2015-05-21)

[Full Changelog](https://github.com/fog/fog-aws/compare/v0.2.2...v0.3.0)

**Closed issues:**

- How to determine the disableApiTermination attribute value  [\#98](https://github.com/fog/fog-aws/issues/98)

**Merged pull requests:**

- support iam/get\_user without username [\#114](https://github.com/fog/fog-aws/pull/114) ([lanej](https://github.com/lanej))
- Added a new request - describe\_instance\_attribute [\#110](https://github.com/fog/fog-aws/pull/110) ([nilroy](https://github.com/nilroy))

## [v0.2.2](https://github.com/fog/fog-aws/tree/v0.2.2) (2015-05-13)

[Full Changelog](https://github.com/fog/fog-aws/compare/v0.2.1...v0.2.2)

## [v0.2.1](https://github.com/fog/fog-aws/tree/v0.2.1) (2015-05-13)

[Full Changelog](https://github.com/fog/fog-aws/compare/v0.2.0...v0.2.1)

**Merged pull requests:**

- mocks for topic permissions [\#111](https://github.com/fog/fog-aws/pull/111) ([lanej](https://github.com/lanej))

## [v0.2.0](https://github.com/fog/fog-aws/tree/v0.2.0) (2015-05-13)

[Full Changelog](https://github.com/fog/fog-aws/compare/v0.1.2...v0.2.0)

**Implemented enhancements:**

- update RDS to 2014-10-31 version [\#107](https://github.com/fog/fog-aws/pull/107) ([lanej](https://github.com/lanej))

**Closed issues:**

- IAM authentication not compatible with GovCloud  [\#100](https://github.com/fog/fog-aws/issues/100)
- Enabling termination protection [\#95](https://github.com/fog/fog-aws/issues/95)
- SSLv3 deprecation: action required? [\#88](https://github.com/fog/fog-aws/issues/88)

**Merged pull requests:**

- configure server attributes in mock [\#109](https://github.com/fog/fog-aws/pull/109) ([michelleN](https://github.com/michelleN))
- support aws kms [\#108](https://github.com/fog/fog-aws/pull/108) ([lanej](https://github.com/lanej))
- Another attempt to solve content-encoding header issues [\#106](https://github.com/fog/fog-aws/pull/106) ([fcheung](https://github.com/fcheung))
- default replica AutoMinorVersionUpgrade to master [\#104](https://github.com/fog/fog-aws/pull/104) ([michelleN](https://github.com/michelleN))
- Refresh credentials if needed when signing S3 URL [\#103](https://github.com/fog/fog-aws/pull/103) ([matkam](https://github.com/matkam))
- Allow the IAM constructor to accept a region [\#102](https://github.com/fog/fog-aws/pull/102) ([benbalter](https://github.com/benbalter))
- configure auto\_minor\_version\_upgrade in mock [\#101](https://github.com/fog/fog-aws/pull/101) ([michelleN](https://github.com/michelleN))
- Adding instanceTenancy to reserved instance parser. [\#97](https://github.com/fog/fog-aws/pull/97) ([dmbrooking](https://github.com/dmbrooking))
- Parse elasticache configuration endpoint from response [\#96](https://github.com/fog/fog-aws/pull/96) ([fcheung](https://github.com/fcheung))
- Fix mock VPC ELB creation in regions other than us-east-1 [\#94](https://github.com/fog/fog-aws/pull/94) ([mrpoundsign](https://github.com/mrpoundsign))
- Fix repository URL in README.md [\#91](https://github.com/fog/fog-aws/pull/91) ([tricknotes](https://github.com/tricknotes))
- adding support for d2 instance type [\#90](https://github.com/fog/fog-aws/pull/90) ([yumminhuang](https://github.com/yumminhuang))
- Support weight round robin mock [\#89](https://github.com/fog/fog-aws/pull/89) ([freddy61025](https://github.com/freddy61025))
- Update README.md [\#87](https://github.com/fog/fog-aws/pull/87) ([nomadium](https://github.com/nomadium))
- Add mock for EC2 request\_spot\_instances API request [\#86](https://github.com/fog/fog-aws/pull/86) ([nomadium](https://github.com/nomadium))
- Move more requires to autoload [\#85](https://github.com/fog/fog-aws/pull/85) ([plribeiro3000](https://github.com/plribeiro3000))
- Add mock for EC2 describe\_spot\_price\_history API request [\#84](https://github.com/fog/fog-aws/pull/84) ([nomadium](https://github.com/nomadium))

## [v0.1.2](https://github.com/fog/fog-aws/tree/v0.1.2) (2015-04-07)

[Full Changelog](https://github.com/fog/fog-aws/compare/v0.1.1...v0.1.2)

**Closed issues:**

- Ruby warnings Comparable & Return nil  [\#81](https://github.com/fog/fog-aws/issues/81)
- CircleCI failing [\#80](https://github.com/fog/fog-aws/issues/80)
- Heroku error [\#77](https://github.com/fog/fog-aws/issues/77)
- Repeatable signed urls for the same expiry [\#65](https://github.com/fog/fog-aws/issues/65)

**Merged pull requests:**

- Handle missing parameters in describe\_spot\_price\_history request [\#82](https://github.com/fog/fog-aws/pull/82) ([nomadium](https://github.com/nomadium))
- create db instance in the correct region [\#79](https://github.com/fog/fog-aws/pull/79) ([lanej](https://github.com/lanej))
- Remove assignment within conditional in File\#body [\#78](https://github.com/fog/fog-aws/pull/78) ([greysteil](https://github.com/greysteil))
- mock DescribeDBEngineVersions [\#76](https://github.com/fog/fog-aws/pull/76) ([ehowe](https://github.com/ehowe))
- Fix blank content-encoding when none is supplied [\#75](https://github.com/fog/fog-aws/pull/75) ([fcheung](https://github.com/fcheung))
- \[rds\] prevent final snapshot on replicas [\#74](https://github.com/fog/fog-aws/pull/74) ([lanej](https://github.com/lanej))
- Fix for `undefined method `map' for nil:NilClass` [\#73](https://github.com/fog/fog-aws/pull/73) ([mattheworiordan](https://github.com/mattheworiordan))
- Resource record sets bug fix + support eu-central-1  [\#72](https://github.com/fog/fog-aws/pull/72) ([mattheworiordan](https://github.com/mattheworiordan))
- Fix EC2 security groups where SSH inbound rule isn't first [\#71](https://github.com/fog/fog-aws/pull/71) ([ayumi](https://github.com/ayumi))
- eu-central missing from Fog::Compute::AWS::Mock [\#70](https://github.com/fog/fog-aws/pull/70) ([wyhaines](https://github.com/wyhaines))
- Remove executable bit from files. [\#69](https://github.com/fog/fog-aws/pull/69) ([voxik](https://github.com/voxik))
- Remove Mac specific files. [\#68](https://github.com/fog/fog-aws/pull/68) ([voxik](https://github.com/voxik))
- Stringify keys for query parameters [\#67](https://github.com/fog/fog-aws/pull/67) ([jfmyers9](https://github.com/jfmyers9))
- Mock method for AWS S3 post\_object\_hidden\_fields  [\#63](https://github.com/fog/fog-aws/pull/63) ([byterussian](https://github.com/byterussian))
- Reduce loading time [\#62](https://github.com/fog/fog-aws/pull/62) ([plribeiro3000](https://github.com/plribeiro3000))
- Add support for cname buckets [\#61](https://github.com/fog/fog-aws/pull/61) ([dsgh](https://github.com/dsgh))

## [v0.1.1](https://github.com/fog/fog-aws/tree/v0.1.1) (2015-02-25)

[Full Changelog](https://github.com/fog/fog-aws/compare/v0.1.0...v0.1.1)

**Closed issues:**

- head\_url signed [\#47](https://github.com/fog/fog-aws/issues/47)
- AWS Credentials required when using IAM Profile [\#44](https://github.com/fog/fog-aws/issues/44)

**Merged pull requests:**

- Support for IAM managed policies [\#60](https://github.com/fog/fog-aws/pull/60) ([fcheung](https://github.com/fcheung))
- Fix for ScanFilter parameters [\#58](https://github.com/fog/fog-aws/pull/58) ([nawaidshamim](https://github.com/nawaidshamim))
- \[dns\] fix Records\#get, mock records and proper errors [\#57](https://github.com/fog/fog-aws/pull/57) ([lanej](https://github.com/lanej))
- \[aws|compute\] support c4.8xlarge flavor [\#56](https://github.com/fog/fog-aws/pull/56) ([ddoc](https://github.com/ddoc))
- \[aws|compute\] adding support for c4 instance class [\#55](https://github.com/fog/fog-aws/pull/55) ([ddoc](https://github.com/ddoc))
- not allowed to delete a "revoking" rds firewall [\#54](https://github.com/fog/fog-aws/pull/54) ([lanej](https://github.com/lanej))
- raise when destroying an ec2 firewall authorized to an rds firewall [\#53](https://github.com/fog/fog-aws/pull/53) ([lanej](https://github.com/lanej))
- Making it easier to get pre-signed head requests [\#51](https://github.com/fog/fog-aws/pull/51) ([mrloop](https://github.com/mrloop))
- Support customer encryption headers in multipart uploads [\#50](https://github.com/fog/fog-aws/pull/50) ([lautis](https://github.com/lautis))
- don't allow sg authorization to unknown sgs [\#49](https://github.com/fog/fog-aws/pull/49) ([lanej](https://github.com/lanej))

## [v0.1.0](https://github.com/fog/fog-aws/tree/v0.1.0) (2015-02-03)

[Full Changelog](https://github.com/fog/fog-aws/compare/v0.0.8...v0.1.0)

**Closed issues:**

- AWS Launch Configuration missing Ebs.Volume\_Type [\#18](https://github.com/fog/fog-aws/issues/18)

**Merged pull requests:**

- Fix v4 signature when path has repeated slashes in the middle [\#46](https://github.com/fog/fog-aws/pull/46) ([fcheung](https://github.com/fcheung))
- get signin token for federation [\#45](https://github.com/fog/fog-aws/pull/45) ([ehowe](https://github.com/ehowe))
- add 'volumeType' and 'encrypted' to blockDeviceMapping parser [\#43](https://github.com/fog/fog-aws/pull/43) ([ichii386](https://github.com/ichii386))
- add missing mocks [\#41](https://github.com/fog/fog-aws/pull/41) ([michelleN](https://github.com/michelleN))
- Add idempotent excon option to some route53 API calls [\#40](https://github.com/fog/fog-aws/pull/40) ([josacar](https://github.com/josacar))
- Allow for AWS errors not specifying region [\#39](https://github.com/fog/fog-aws/pull/39) ([greysteil](https://github.com/greysteil))
- correct engine version param on rds replicas [\#38](https://github.com/fog/fog-aws/pull/38) ([lanej](https://github.com/lanej))
- default namespace and evaluation period on alarm [\#37](https://github.com/fog/fog-aws/pull/37) ([michelleN](https://github.com/michelleN))
- \[AWS|Autoscaling\] Add missing ebs attributes to describe\_launch\_configurations [\#35](https://github.com/fog/fog-aws/pull/35) ([fcheung](https://github.com/fcheung))
- \[AWS|Storage\] signed\_url should use v2 signature when aws\_signature\_version is 2 [\#34](https://github.com/fog/fog-aws/pull/34) ([fcheung](https://github.com/fcheung))
- BUGFIX: When fog\_credentials endpoint is set @region defaults to nil [\#33](https://github.com/fog/fog-aws/pull/33) ([nicholasklick](https://github.com/nicholasklick))
- \[AWS|Autoscaling\] Support classic link related properties for launch configurations [\#32](https://github.com/fog/fog-aws/pull/32) ([fcheung](https://github.com/fcheung))
- fix autoscaling activities collection setup [\#31](https://github.com/fog/fog-aws/pull/31) ([fcheung](https://github.com/fcheung))
- Add PlacementTenancy to launch configuration parser and test case [\#29](https://github.com/fog/fog-aws/pull/29) ([benpillet](https://github.com/benpillet))
- Use Fog::Formatador [\#27](https://github.com/fog/fog-aws/pull/27) ([ghost](https://github.com/ghost))

## [v0.0.8](https://github.com/fog/fog-aws/tree/v0.0.8) (2015-01-27)

[Full Changelog](https://github.com/fog/fog-aws/compare/v0.0.7...v0.0.8)

**Closed issues:**

- NoMethodError - undefined method `signature\_parameters' for nil:NilClass [\#28](https://github.com/fog/fog-aws/issues/28)

## [v0.0.7](https://github.com/fog/fog-aws/tree/v0.0.7) (2015-01-23)

[Full Changelog](https://github.com/fog/fog-aws/compare/v0.0.6...v0.0.7)

**Closed issues:**

- SSL Error on S3 connection [\#9](https://github.com/fog/fog-aws/issues/9)

**Merged pull requests:**

- simulate sns confirmation message [\#36](https://github.com/fog/fog-aws/pull/36) ([lanej](https://github.com/lanej))
- Support for VPC Classic Link [\#3](https://github.com/fog/fog-aws/pull/3) ([fcheung](https://github.com/fcheung))

## [v0.0.6](https://github.com/fog/fog-aws/tree/v0.0.6) (2015-01-12)

[Full Changelog](https://github.com/fog/fog-aws/compare/v0.0.5...v0.0.6)

**Closed issues:**

- missed files [\#1](https://github.com/fog/fog-aws/issues/1)

**Merged pull requests:**

- \[AWS|Core\] Fix signature v4 non canonicalising header case properly [\#4](https://github.com/fog/fog-aws/pull/4) ([fcheung](https://github.com/fcheung))
- another attempt at s3 region redirecting [\#2](https://github.com/fog/fog-aws/pull/2) ([geemus](https://github.com/geemus))

## [v0.0.5](https://github.com/fog/fog-aws/tree/v0.0.5) (2015-01-06)

[Full Changelog](https://github.com/fog/fog-aws/compare/v0.0.4...v0.0.5)

## [v0.0.4](https://github.com/fog/fog-aws/tree/v0.0.4) (2015-01-04)

[Full Changelog](https://github.com/fog/fog-aws/compare/v0.0.3...v0.0.4)

## [v0.0.3](https://github.com/fog/fog-aws/tree/v0.0.3) (2015-01-02)

[Full Changelog](https://github.com/fog/fog-aws/compare/v0.0.2...v0.0.3)

## [v0.0.2](https://github.com/fog/fog-aws/tree/v0.0.2) (2015-01-02)

[Full Changelog](https://github.com/fog/fog-aws/compare/v0.0.1...v0.0.2)

## [v0.0.1](https://github.com/fog/fog-aws/tree/v0.0.1) (2015-01-02)

[Full Changelog](https://github.com/fog/fog-aws/compare/rm...v0.0.1)

## [rm](https://github.com/fog/fog-aws/tree/rm) (2014-11-27)

[Full Changelog](https://github.com/fog/fog-aws/compare/fog-brightbox_v0.0.1...rm)

## [fog-brightbox_v0.0.1](https://github.com/fog/fog-aws/tree/fog-brightbox_v0.0.1) (2014-02-19)

[Full Changelog](https://github.com/fog/fog-aws/compare/d496bcd266d584ffcded6e265e8166138a3fb22a...fog-brightbox_v0.0.1)



\* *This Changelog was automatically generated by [github_changelog_generator](https://github.com/github-changelog-generator/github-changelog-generator)*
