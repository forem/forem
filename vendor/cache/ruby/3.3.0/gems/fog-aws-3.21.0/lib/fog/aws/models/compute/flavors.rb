require 'fog/aws/models/compute/flavor'

# To compute RAM from AWS doc https://aws.amazon.com/fr/ec2/instance-types
# we can use this formula: RAM (in MB) = AWS_RAM (in GiB) * 1073.742 MB/GiB
module Fog
  module AWS
    class Compute
      FLAVORS = [
        {
          :id                      => 'a1.medium',
          :name                    => 'A1 Medium Instance',
          :bits                    => 64,
          :cores                   => 1,
          :disk                    => 0,
          :ram                     => 2147,
          :ebs_optimized_available => false,
          :instance_store_volumes  => 0
        },
        {
          :id                      => 'a1.large',
          :name                    => 'A1 Large Instance',
          :bits                    => 64,
          :cores                   => 2,
          :disk                    => 0,
          :ram                     => 4295,
          :ebs_optimized_available => false,
          :instance_store_volumes  => 0
        },
        {
          :id                      => 'a1.xlarge',
          :name                    => 'A1 Extra Large Instance',
          :bits                    => 64,
          :cores                   => 4,
          :disk                    => 0,
          :ram                     => 8590,
          :ebs_optimized_available => false,
          :instance_store_volumes  => 0
        },
        {
          :id                      => 'a1.2xlarge',
          :name                    => 'A1 Double Extra Large Instance',
          :bits                    => 64,
          :cores                   => 8,
          :disk                    => 0,
          :ram                     => 17180,
          :ebs_optimized_available => false,
          :instance_store_volumes  => 0
        },
        {
          :id                      => 'a1.4xlarge',
          :name                    => 'A1 Quadruple Extra Large Instance',
          :bits                    => 64,
          :cores                   => 16,
          :disk                    => 0,
          :ram                     => 34360,
          :ebs_optimized_available => false,
          :instance_store_volumes  => 0
        },
        {
          :id                      => 'a1.metal',
          :name                    => 'A1 Metal',
          :bits                    => 64,
          :cores                   => 16,
          :disk                    => 0,
          :ram                     => 34360,
          :ebs_optimized_available => false,
          :instance_store_volumes  => 0
        },
        {
          :id                      => 't1.micro',
          :name                    => 'T1 Micro Instance',
          :bits                    => 32,
          :cores                   => 1,
          :disk                    => 0,
          :ram                     => 658,
          :ebs_optimized_available => false,
          :instance_store_volumes  => 0
        },
        {
          :id                      => 't2.nano',
          :name                    => 'Nano Instance',
          :bits                    => 64,
          :cores                   => 1,
          :disk                    => 0,
          :ram                     => 536,
          :ebs_optimized_available => false,
          :instance_store_volumes  => 0
        },
        {
          :id                      => 't2.micro',
          :name                    => 'T2 Micro Instance',
          :bits                    => 64,
          :cores                   => 1,
          :disk                    => 0,
          :ram                     => 1073,
          :ebs_optimized_available => false,
          :instance_store_volumes  => 0
        },
        {
          :id                      => 't2.small',
          :name                    => 'T2 Small Instance',
          :bits                    => 64,
          :cores                   => 1,
          :disk                    => 0,
          :ram                     => 2147,
          :ebs_optimized_available => false,
          :instance_store_volumes  => 0
        },
        {
          :id                      => 't2.medium',
          :name                    => 'T2 Medium Instance',
          :bits                    => 64,
          :cores                   => 2,
          :disk                    => 0,
          :ram                     => 4294,
          :ebs_optimized_available => false,
          :instance_store_volumes  => 0
        },
        {
          :id                      => 't2.large',
          :name                    => 'T2 Large Instance',
          :bits                    => 64,
          :cores                   => 2,
          :disk                    => 0,
          :ram                     => 8589,
          :ebs_optimized_available => false,
          :instance_store_volumes  => 0
        },
        {
          :id                      => 't2.xlarge',
          :name                    => 'T2 Extra Large Instance',
          :bits                    => 64,
          :cores                   => 4,
          :disk                    => 0,
          :ram                     => 17179,
          :ebs_optimized_available => false,
          :instance_store_volumes  => 0
        },
        {
          :id                      => 't2.2xlarge',
          :name                    => 'T2 Double Extra Large Instance',
          :bits                    => 64,
          :cores                   => 8,
          :disk                    => 0,
          :ram                     => 34359,
          :ebs_optimized_available => false,
          :instance_store_volumes  => 0
        },
        {
          :id                      => 't3.nano',
          :name                    => 'T3 Nano',
          :bits                    => 64,
          :cores                   => 2,
          :disk                    => 0,
          :ram                     => 536,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 0
        },
        {
          :id                      => 't3.micro',
          :name                    => 'T3 Micro',
          :bits                    => 64,
          :cores                   => 2,
          :disk                    => 0,
          :ram                     => 1073,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 0
        },
        {
          :id                      => 't3.small',
          :name                    => 'T3 Small',
          :bits                    => 64,
          :cores                   => 2,
          :disk                    => 0,
          :ram                     => 2147,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 0
        },
        {
          :id                      => 't3.medium',
          :name                    => 'T3 Medium',
          :bits                    => 64,
          :cores                   => 2,
          :disk                    => 0,
          :ram                     => 4294,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 0
        },
        {
          :id                      => 't3.large',
          :name                    => 'T3 Large',
          :bits                    => 64,
          :cores                   => 2,
          :disk                    => 0,
          :ram                     => 8589,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 0
        },
        {
          :id                      => 't3.xlarge',
          :name                    => 'T3 Extra Large',
          :bits                    => 64,
          :cores                   => 4,
          :disk                    => 0,
          :ram                     => 17179,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 0
        },
        {
          :id                      => 't3.2xlarge',
          :name                    => 'T3 Double Extra Large',
          :bits                    => 64,
          :cores                   => 8,
          :disk                    => 0,
          :ram                     => 34359,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 0
        },
        {
          :id                      => 't3a.nano',
          :name                    => 'T3a Nano',
          :bits                    => 64,
          :cores                   => 2,
          :disk                    => 0,
          :ram                     => 536,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 0
        },
        {
          :id                      => 't3a.micro',
          :name                    => 'T3a Micro',
          :bits                    => 64,
          :cores                   => 2,
          :disk                    => 0,
          :ram                     => 1073,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 0
        },
        {
          :id                      => 't3a.small',
          :name                    => 'T3a Small',
          :bits                    => 64,
          :cores                   => 2,
          :disk                    => 0,
          :ram                     => 2147,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 0
        },
        {
          :id                      => 't3a.medium',
          :name                    => 'T3a Medium',
          :bits                    => 64,
          :cores                   => 2,
          :disk                    => 0,
          :ram                     => 4294,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 0
        },
        {
          :id                      => 't3a.large',
          :name                    => 'T3a Large',
          :bits                    => 64,
          :cores                   => 2,
          :disk                    => 0,
          :ram                     => 8589,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 0
        },
        {
          :id                      => 't3a.xlarge',
          :name                    => 'T3a Extra Large',
          :bits                    => 64,
          :cores                   => 4,
          :disk                    => 0,
          :ram                     => 17179,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 0
        },
        {
          :id                      => 't3a.2xlarge',
          :name                    => 'T3a Double Extra Large',
          :bits                    => 64,
          :cores                   => 8,
          :disk                    => 0,
          :ram                     => 34359,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 0
        },
        {
          :id                      => 't4g.nano',
          :name                    => 'T4G Nano Instace',
          :bits                    => 64,
          :cores                   => 2,
          :disk                    => 0,
          :ram                     => 537,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 0
        },
        {
          :id                      => 't4g.micro',
          :name                    => 'T4G Micro Instance',
          :bits                    => 64,
          :cores                   => 2,
          :disk                    => 0,
          :ram                     => 1073,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 0
        },
        {
          :id                      => 't4g.small',
          :name                    => 'T4G Small Instance',
          :bits                    => 64,
          :cores                   => 2,
          :disk                    => 0,
          :ram                     => 2147,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 0
        },
        {
          :id                      => 't4g.medium',
          :name                    => 'T4G Medium Instace',
          :bits                    => 64,
          :cores                   => 2,
          :disk                    => 0,
          :ram                     => 4295,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 0
        },
        {
          :id                      => 't4g.large',
          :name                    => 'T4G Large Instance',
          :bits                    => 64,
          :cores                   => 2,
          :disk                    => 0,
          :ram                     => 8590,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 0
        },
        {
          :id                      => 't4g.xlarge',
          :name                    => 'T4G Extra Large Instance',
          :bits                    => 64,
          :cores                   => 4,
          :disk                    => 0,
          :ram                     => 17180,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 0
        },
        {
          :id                      => 't4g.2xlarge',
          :name                    => 'T4G Double Extra Large Instance',
          :bits                    => 64,
          :cores                   => 8,
          :disk                    => 0,
          :ram                     => 34360,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 0
        },
        {
          :id                      => 'm6g.medium',
          :name                    => 'M6G Medium',
          :bits                    => 64,
          :cores                   => 1,
          :disk                    => 0,
          :ram                     => 4295,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 0
        },
        {
          :id                      => 'm6g.large',
          :name                    => 'M6G Large',
          :bits                    => 64,
          :cores                   => 2,
          :disk                    => 0,
          :ram                     => 8590,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 0
        },
        {
          :id                      => 'm6g.xlarge',
          :name                    => 'M6G Extra Large',
          :bits                    => 64,
          :cores                   => 4,
          :disk                    => 0,
          :ram                     => 17180,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 0
        },
        {
          :id                      => 'm6g.2xlarge',
          :name                    => 'M6G Double Extra Large',
          :bits                    => 64,
          :cores                   => 8,
          :disk                    => 0,
          :ram                     => 34360,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 0
        },
        {
          :id                      => 'm6g.4xlarge',
          :name                    => 'M6G Quadruple Extra Large',
          :bits                    => 64,
          :cores                   => 16,
          :disk                    => 0,
          :ram                     => 68719,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 0
        },
        {
          :id                      => 'm6g.8xlarge',
          :name                    => 'M6G Octuple Extra Large',
          :bits                    => 64,
          :cores                   => 32,
          :disk                    => 0,
          :ram                     => 137439,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 0
        },
        {
          :id                      => 'm6g.12xlarge',
          :name                    => 'M6G Twelve Extra Large',
          :bits                    => 64,
          :cores                   => 48,
          :disk                    => 0,
          :ram                     => 206158,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 0
        },
        {
          :id                      => 'm6g.16xlarge',
          :name                    => 'M6G Sixteen Extra Large',
          :bits                    => 64,
          :cores                   => 64,
          :disk                    => 0,
          :ram                     => 274878,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 0
        },
        {
          :id                      => 'm6g.metal',
          :name                    => 'M6G Metal',
          :bits                    => 64,
          :cores                   => 64,
          :disk                    => 0,
          :ram                     => 274878,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 0
        },
        {
          :id                      => 'm6gd.medium',
          :name                    => 'M6GD Medium',
          :bits                    => 64,
          :cores                   => 1,
          :disk                    => 59,
          :ram                     => 4295,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 1
        },
        {
          :id                      => 'm6gd.large',
          :name                    => 'M6GD Large',
          :bits                    => 64,
          :cores                   => 2,
          :disk                    => 118,
          :ram                     => 8590,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 1
        },
        {
          :id                      => 'm6gd.xlarge',
          :name                    => 'M6GD Extra Large',
          :bits                    => 64,
          :cores                   => 4,
          :disk                    => 237,
          :ram                     => 17180,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 1
        },
        {
          :id                      => 'm6gd.2xlarge',
          :name                    => 'M6GD Double Extra Large',
          :bits                    => 64,
          :cores                   => 8,
          :disk                    => 474,
          :ram                     => 34360,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 1
        },
        {
          :id                      => 'm6gd.4xlarge',
          :name                    => 'M6GD Quadruple Extra Large',
          :bits                    => 64,
          :cores                   => 16,
          :disk                    => 950,
          :ram                     => 68719,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 1
        },
        {
          :id                      => 'm6gd.8xlarge',
          :name                    => 'M6GD Octuple Extra Large',
          :bits                    => 64,
          :cores                   => 32,
          :disk                    => 1900,
          :ram                     => 137439,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 1
        },
        {
          :id                      => 'm6gd.12xlarge',
          :name                    => 'M6GD Twelve Extra Large',
          :bits                    => 64,
          :cores                   => 48,
          :disk                    => 2850,
          :ram                     => 206158,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 2
        },
        {
          :id                      => 'm6gd.16xlarge',
          :name                    => 'M6GD Sixteen Extra Large',
          :bits                    => 64,
          :cores                   => 64,
          :disk                    => 3800,
          :ram                     => 274878,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 2
        },
        {
          :id                      => 'm6gd.metal',
          :name                    => 'M6GD Metal',
          :bits                    => 64,
          :cores                   => 64,
          :disk                    => 3800,
          :ram                     => 274878,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 2
        },
        {
          :id                      => 'm1.small',
          :name                    => 'M1 Small Instance',
          :bits                    => 32,
          :cores                   => 1,
          :disk                    => 160,
          :ram                     => 1825,
          :ebs_optimized_available => false,
          :instance_store_volumes  => 1
        },
        {
          :id                      => 'm1.medium',
          :name                    => 'M1 Medium Instance',
          :bits                    => 32,
          :cores                   => 1,
          :disk                    => 400,
          :ram                     => 4026,
          :ebs_optimized_available => false,
          :instance_store_volumes  => 1
        },
        {
          :id                      => 'm1.large',
          :name                    => 'M1 Large Instance',
          :bits                    => 64,
          :cores                   => 2,
          :disk                    => 850,
          :ram                     => 8053,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 2
        },
        {
          :id                      => 'm1.xlarge',
          :name                    => 'M1 Extra Large Instance',
          :bits                    => 64,
          :cores                   => 4,
          :disk                    => 1690,
          :ram                     => 16106,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 4
        },
        {
          :id                      => 'c1.medium',
          :bits                    => 32,
          :cores                   => 2,
          :disk                    => 350,
          :name                    => 'High-CPU Medium',
          :ram                     => 1825,
          :ebs_optimized_available => false,
          :instance_store_volumes  => 1
        },
        {
          :id                      => 'c1.xlarge',
          :name                    => 'High-CPU Extra Large',
          :bits                    => 64,
          :cores                   => 8,
          :disk                    => 1690,
          :ram                     => 7516,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 4
        },
        {
          :id                      => 'c3.large',
          :name                    => 'C3 Large',
          :bits                    => 64,
          :cores                   => 2,
          :disk                    => 32,
          :ram                     => 4026,
          :ebs_optimized_available => false,
          :instance_store_volumes  => 2
        },
        {
          :id                      => 'c3.xlarge',
          :name                    => 'C3 Extra Large',
          :bits                    => 64,
          :cores                   => 4,
          :disk                    => 80,
          :ram                     => 8053,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 2
        },
        {
          :id                      => 'c3.2xlarge',
          :name                    => 'C3 Double Extra Large',
          :bits                    => 64,
          :cores                   => 8,
          :disk                    => 160,
          :ram                     => 16106,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 2
        },
        {
          :id                      => 'c3.4xlarge',
          :name                    => 'C3 Quadruple Extra Large',
          :bits                    => 64,
          :cores                   => 16,
          :disk                    => 320,
          :ram                     => 32212,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 2
        },
        {
          :id                      => 'c3.8xlarge',
          :name                    => 'C3 Eight Extra Large',
          :bits                    => 64,
          :cores                   => 32,
          :disk                    => 640,
          :ram                     => 64424,
          :ebs_optimized_available => false,
          :instance_store_volumes  => 2
        },
        {
          :id                      => 'c4.large',
          :name                    => 'C4 Large',
          :bits                    => 64,
          :cores                   => 2,
          :disk                    => 0,
          :ram                     => 4026,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 0
        },
        {
          :id                      => 'c4.xlarge',
          :name                    => 'C4 Extra Large',
          :bits                    => 64,
          :cores                   => 4,
          :disk                    => 0,
          :ram                     => 8053,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 0
        },
        {
          :id                      => 'c4.2xlarge',
          :name                    => 'C4 Double Extra Large',
          :bits                    => 64,
          :cores                   => 8,
          :disk                    => 0,
          :ram                     => 16106,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 0
        },
        {
          :id                      => 'c4.4xlarge',
          :name                    => 'C4 Quadruple Extra Large',
          :bits                    => 64,
          :cores                   => 16,
          :disk                    => 0,
          :ram                     => 32212,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 0
        },
        {
          :id                      => 'c4.8xlarge',
          :name                    => 'C4 Eight Extra Large',
          :bits                    => 64,
          :cores                   => 36,
          :disk                    => 0,
          :ram                     => 64424,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 0
        },
        {
          :id                      => 'c5.large',
          :name                    => 'C5 Large',
          :bits                    => 64,
          :cores                   => 2,
          :disk                    => 0,
          :ram                     => 4294,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 0
        },
        {
          :id                      => 'c5.xlarge',
          :name                    => 'C5 Extra Large',
          :bits                    => 64,
          :cores                   => 4,
          :disk                    => 0,
          :ram                     => 8589,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 0
        },
        {
          :id                      => 'c5.2xlarge',
          :name                    => 'C5 Double Extra Large',
          :bits                    => 64,
          :cores                   => 8,
          :disk                    => 0,
          :ram                     => 17179,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 0
        },
        {
          :id                      => 'c5.4xlarge',
          :name                    => 'C5 Quadruple Extra Large',
          :bits                    => 64,
          :cores                   => 16,
          :disk                    => 0,
          :ram                     => 34359,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 0
        },
        {
          :id                      => 'c5.9xlarge',
          :name                    => 'C5 Nine Extra Large',
          :bits                    => 64,
          :cores                   => 36,
          :disk                    => 0,
          :ram                     => 77309,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 0
        },
        {
          :id                      => 'c5.12xlarge',
          :name                    => 'C5 Twelve Extra Large',
          :bits                    => 64,
          :cores                   => 48,
          :disk                    => 0,
          :ram                     => 103079,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 0
        },
        {
          :id                      => 'c5.18xlarge',
          :name                    => 'C5 Eighteen Extra Large',
          :bits                    => 64,
          :cores                   => 72,
          :disk                    => 0,
          :ram                     => 154618,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 0
        },
        {
          :id                      => 'c5.24xlarge',
          :name                    => 'C5 Twenty-Four Extra Large',
          :bits                    => 64,
          :cores                   => 96,
          :disk                    => 0,
          :ram                     => 206158,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 0
        },
        {
          :id                      => 'c5.metal',
          :name                    => 'C5 Metal',
          :bits                    => 64,
          :cores                   => 96,
          :disk                    => 0,
          :ram                     => 206158,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 0
        },
        {
          :id                      => 'c5d.large',
          :name                    => 'C5d Large',
          :bits                    => 64,
          :cores                   => 2,
          :disk                    => 50,
          :ram                     => 4294,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 1
        },
        {
          :id                      => 'c5d.xlarge',
          :name                    => 'C5d Extra Large',
          :bits                    => 64,
          :cores                   => 4,
          :disk                    => 100,
          :ram                     => 8589,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 1
        },
        {
          :id                      => 'c5d.2xlarge',
          :name                    => 'C5d Double Extra Large',
          :bits                    => 64,
          :cores                   => 8,
          :disk                    => 200,
          :ram                     => 17179,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 1
        },
        {
          :id                      => 'c5d.4xlarge',
          :name                    => 'C5d Quadruple Extra Large',
          :bits                    => 64,
          :cores                   => 16,
          :disk                    => 400,
          :ram                     => 34359,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 1
        },
        {
          :id                      => 'c5d.9xlarge',
          :name                    => 'C5d Nine Extra Large',
          :bits                    => 64,
          :cores                   => 36,
          :disk                    => 900,
          :ram                     => 77309,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 1
        },
        {
          :id                      => 'c5d.12xlarge',
          :name                    => 'C5d Twelve Extra Large',
          :bits                    => 64,
          :cores                   => 48,
          :disk                    => 1800,
          :ram                     => 103079,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 2
        },
        {
          :id                      => 'c5d.18xlarge',
          :name                    => 'C5d Eighteen Extra Large',
          :bits                    => 64,
          :cores                   => 72,
          :disk                    => 1800,
          :ram                     => 154618,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 2
        },
        {
          :id                      => 'c5d.24xlarge',
          :name                    => 'C5d Twenty-four Extra Large',
          :bits                    => 64,
          :cores                   => 96,
          :disk                    => 3600,
          :ram                     => 206158,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 4
        },
        {
          :id                      => 'c5d.metal',
          :name                    => 'C5d Metal',
          :bits                    => 64,
          :cores                   => 96,
          :disk                    => 3600,
          :ram                     => 206158,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 4
        },
        {
          :id                      => 'c5n.large',
          :name                    => 'C5n Large',
          :bits                    => 64,
          :cores                   => 2,
          :disk                    => 0,
          :ram                     => 5637,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 0
        },
        {
          :id                      => 'c5n.xlarge',
          :name                    => 'C5n Extra Large',
          :bits                    => 64,
          :cores                   => 4,
          :disk                    => 0,
          :ram                     => 11274,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 0
        },
        {
          :id                      => 'c5n.2xlarge',
          :name                    => 'C5n Double Extra Large',
          :bits                    => 64,
          :cores                   => 8,
          :disk                    => 0,
          :ram                     => 22549,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 0
        },
        {
          :id                      => 'c5n.4xlarge',
          :name                    => 'C5n Quadruple Extra Large',
          :bits                    => 64,
          :cores                   => 16,
          :disk                    => 0,
          :ram                     => 45097,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 0
        },
        {
          :id                      => 'c5n.9xlarge',
          :name                    => 'C5n Nine Extra Large',
          :bits                    => 64,
          :cores                   => 36,
          :disk                    => 0,
          :ram                     => 103079,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 0
        },
        {
          :id                      => 'c5n.18xlarge',
          :name                    => 'C5n Eighteen Extra Large',
          :bits                    => 64,
          :cores                   => 72,
          :disk                    => 0,
          :ram                     => 206158,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 0
        },
        {
          :id                      => 'c5n.metal',
          :name                    => 'C5n Metal',
          :bits                    => 64,
          :cores                   => 72,
          :disk                    => 0,
          :ram                     => 206158,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 0
        },
        {
          :id                      => 'c6g.medium',
          :name                    => 'C6G Medium',
          :bits                    => 64,
          :cores                   => 1,
          :disk                    => 0,
          :ram                     => 2147,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 0
        },
        {
          :id                      => 'c6g.large',
          :name                    => 'C6G Large',
          :bits                    => 64,
          :cores                   => 2,
          :disk                    => 0,
          :ram                     => 4295,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 0
        },
        {
          :id                      => 'c6g.xlarge',
          :name                    => 'C6G Extra Large',
          :bits                    => 64,
          :cores                   => 4,
          :disk                    => 0,
          :ram                     => 8590,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 0
        },
        {
          :id                      => 'c6g.2xlarge',
          :name                    => 'C6G Double Extra Large',
          :bits                    => 64,
          :cores                   => 8,
          :disk                    => 0,
          :ram                     => 17180,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 0
        },
        {
          :id                      => 'c6g.4xlarge',
          :name                    => 'C6G Quadruple Extra Large',
          :bits                    => 64,
          :cores                   => 16,
          :disk                    => 0,
          :ram                     => 34360,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 0
        },
        {
          :id                      => 'c6g.8xlarge',
          :name                    => 'C6G Octuple Extra Large',
          :bits                    => 64,
          :cores                   => 32,
          :disk                    => 0,
          :ram                     => 68719,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 0
        },
        {
          :id                      => 'c6g.12xlarge',
          :name                    => 'C6G Twelve Extra Large',
          :bits                    => 64,
          :cores                   => 48,
          :disk                    => 0,
          :ram                     => 103079,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 0
        },
        {
          :id                      => 'c6g.16xlarge',
          :name                    => 'C6G Sixteen Extra Large',
          :bits                    => 64,
          :cores                   => 64,
          :disk                    => 0,
          :ram                     => 137439,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 0
        },
        {
          :id                      => 'c6g.metal',
          :name                    => 'C6G Metal',
          :bits                    => 64,
          :cores                   => 64,
          :disk                    => 0,
          :ram                     => 137439,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 0
        },
        {
          :id                      => 'c6gd.medium',
          :name                    => 'C6GD Medium',
          :bits                    => 64,
          :cores                   => 1,
          :disk                    => 59,
          :ram                     => 2147,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 1
        },
        {
          :id                      => 'c6gd.large',
          :name                    => 'C6GD Large',
          :bits                    => 64,
          :cores                   => 2,
          :disk                    => 118,
          :ram                     => 4295,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 1
        },
        {
          :id                      => 'c6gd.xlarge',
          :name                    => 'C6GD Extra Large',
          :bits                    => 64,
          :cores                   => 4,
          :disk                    => 237,
          :ram                     => 8590,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 1
        },
        {
          :id                      => 'c6gd.2xlarge',
          :name                    => 'C6GD Double Extra Large',
          :bits                    => 64,
          :cores                   => 8,
          :disk                    => 474,
          :ram                     => 17180,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 1
        },
        {
          :id                      => 'c6gd.4xlarge',
          :name                    => 'C6GD Quadruple Extra Large',
          :bits                    => 64,
          :cores                   => 16,
          :disk                    => 950,
          :ram                     => 34360,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 1
        },
        {
          :id                      => 'c6gd.8xlarge',
          :name                    => 'C6GD Octuple Extra Large',
          :bits                    => 64,
          :cores                   => 32,
          :disk                    => 1900,
          :ram                     => 68719,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 1
        },
        {
          :id                      => 'c6gd.12xlarge',
          :name                    => 'C6GD Twelve Extra Large',
          :bits                    => 64,
          :cores                   => 48,
          :disk                    => 2850,
          :ram                     => 103079,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 2
        },
        {
          :id                      => 'c6gd.16xlarge',
          :name                    => 'C6GD Sixteen Extra Large',
          :bits                    => 64,
          :cores                   => 64,
          :disk                    => 3800,
          :ram                     => 137439,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 2
        },
        {
          :id                      => 'c6gd.metal',
          :name                    => 'C6GD Metal',
          :bits                    => 64,
          :cores                   => 64,
          :disk                    => 3800,
          :ram                     => 137439,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 2
        },
        {
          :id                      => 'c6a.large',
          :name                    => 'c6a Large',
          :bits                    => 64,
          :cores                   => 2,
          :disk                    => 0,
          :ram                     => 4295,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 0
        },
        {
          :id                      => 'c6a.xlarge',
          :name                    => 'c6a xLarge',
          :bits                    => 64,
          :cores                   => 4,
          :disk                    => 0,
          :ram                     => 8590,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 0
        },
        {
          :id                      => 'c6a.2xlarge',
          :name                    => 'c6a 2xLarge',
          :bits                    => 64,
          :cores                   => 8,
          :disk                    => 0,
          :ram                     => 17180,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 0
        },
        {
          :id                      => 'c6a.4xlarge',
          :name                    => 'c6a 4xLarge',
          :bits                    => 64,
          :cores                   => 16,
          :disk                    => 0,
          :ram                     => 34360,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 0
        },
        {
          :id                      => 'c6a.8xlarge',
          :name                    => 'c6a 8xLarge',
          :bits                    => 64,
          :cores                   => 32,
          :disk                    => 0,
          :ram                     => 68719,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 0
        },
        {
          :id                      => 'c6a.12xlarge',
          :name                    => 'C6a Twelve Extra Large',
          :bits                    => 64,
          :cores                   => 48,
          :disk                    => 0,
          :ram                     => 103079,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 0
        },
        {
          :id                      => 'c6a.16xlarge',
          :name                    => 'c6a 16xLarge',
          :bits                    => 64,
          :cores                   => 64,
          :disk                    => 0,
          :ram                     => 137439,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 0
        },
        {
          :id                      => 'c6a.24xlarge',
          :name                    => 'c6a 24xLarge',
          :bits                    => 64,
          :cores                   => 96,
          :disk                    => 0,
          :ram                     => 206158,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 0
        },
        {
          :id                      => 'c6a.32xlarge',
          :name                    => 'c6a 32xLarge',
          :bits                    => 64,
          :cores                   => 128,
          :disk                    => 0,
          :ram                     => 274878,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 0
        },
        {
          :id                      => 'c6a.48xlarge',
          :name                    => 'c6a 48xLarge',
          :bits                    => 64,
          :cores                   => 192,
          :disk                    => 0,
          :ram                     => 412317,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 0
        },
        {
          :id                      => 'c6a.metal',
          :name                    => 'c6a metal',
          :bits                    => 64,
          :cores                   => 192,
          :disk                    => 0,
          :ram                     => 412317,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 0
        },
        {
          :id                      => 'c6i.large',
          :name                    => 'c6i Large',
          :bits                    => 64,
          :cores                   => 2,
          :disk                    => 0,
          :ram                     => 4295,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 0
        },
        {
          :id                      => 'c6i.xlarge',
          :name                    => 'c6i xLarge',
          :bits                    => 64,
          :cores                   => 4,
          :disk                    => 0,
          :ram                     => 8590,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 0
        },
        {
          :id                      => 'c6i.2xlarge',
          :name                    => 'c6i 2xLarge',
          :bits                    => 64,
          :cores                   => 8,
          :disk                    => 0,
          :ram                     => 17180,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 0
        },
        {
          :id                      => 'c6i.4xlarge',
          :name                    => 'c6i 4xLarge',
          :bits                    => 64,
          :cores                   => 16,
          :disk                    => 0,
          :ram                     => 34360,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 0
        },
        {
          :id                      => 'c6i.8xlarge',
          :name                    => 'c6i 8xLarge',
          :bits                    => 64,
          :cores                   => 32,
          :disk                    => 0,
          :ram                     => 68719,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 0
        },
        {
          :id                      => 'c6i.12xlarge',
          :name                    => 'c6i Twelve Extra Large',
          :bits                    => 64,
          :cores                   => 48,
          :disk                    => 0,
          :ram                     => 103079,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 0
        },
        {
          :id                      => 'c6i.16xlarge',
          :name                    => 'c6i 16xLarge',
          :bits                    => 64,
          :cores                   => 64,
          :disk                    => 0,
          :ram                     => 137439,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 0
        },
        {
          :id                      => 'c6i.24xlarge',
          :name                    => 'c6i 24xLarge',
          :bits                    => 64,
          :cores                   => 96,
          :disk                    => 0,
          :ram                     => 206158,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 0
        },
        {
          :id                      => 'c6i.32xlarge',
          :name                    => 'c6i 32xLarge',
          :bits                    => 64,
          :cores                   => 128,
          :disk                    => 0,
          :ram                     => 274878,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 0
        },
        {
          :id                      => 'c6i.metal',
          :name                    => 'c6i metal',
          :bits                    => 64,
          :cores                   => 128,
          :disk                    => 0,
          :ram                     => 274878,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 0
        },
        {
          :id                      => 'c6in.large',
          :name                    => 'c6in Large',
          :bits                    => 64,
          :cores                   => 2,
          :disk                    => 0,
          :ram                     => 4295,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 0
        },
        {
          :id                      => 'c6in.xlarge',
          :name                    => 'c6in xLarge',
          :bits                    => 64,
          :cores                   => 4,
          :disk                    => 0,
          :ram                     => 8590,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 0
        },
        {
          :id                      => 'c6in.2xlarge',
          :name                    => 'c6in 2xLarge',
          :bits                    => 64,
          :cores                   => 8,
          :disk                    => 0,
          :ram                     => 17180,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 0
        },
        {
          :id                      => 'c6in.4xlarge',
          :name                    => 'c6in 4xLarge',
          :bits                    => 64,
          :cores                   => 16,
          :disk                    => 0,
          :ram                     => 34360,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 0
        },
        {
          :id                      => 'c6in.8xlarge',
          :name                    => 'c6in 8xLarge',
          :bits                    => 64,
          :cores                   => 32,
          :disk                    => 0,
          :ram                     => 68719,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 0
        },
        {
          :id                      => 'c6in.12xlarge',
          :name                    => 'c6in Twelve Extra Large',
          :bits                    => 64,
          :cores                   => 48,
          :disk                    => 0,
          :ram                     => 103079,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 0
        },
        {
          :id                      => 'c6in.16xlarge',
          :name                    => 'c6in 16xLarge',
          :bits                    => 64,
          :cores                   => 64,
          :disk                    => 0,
          :ram                     => 137439,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 0
        },
        {
          :id                      => 'c6in.24xlarge',
          :name                    => 'c6in 24xLarge',
          :bits                    => 64,
          :cores                   => 96,
          :disk                    => 0,
          :ram                     => 206158,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 0
        },
        {
          :id                      => 'c6in.32xlarge',
          :name                    => 'c6in 32xLarge',
          :bits                    => 64,
          :cores                   => 128,
          :disk                    => 0,
          :ram                     => 274878,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 0
        },
        {
          :id                      => 'c6in.metal',
          :name                    => 'c6in metal',
          :bits                    => 64,
          :cores                   => 128,
          :disk                    => 0,
          :ram                     => 274878,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 0
        },
        {
          :id                      => 'c6id.large',
          :name                    => 'c6id Large',
          :bits                    => 64,
          :cores                   => 2,
          :disk                    => 118,
          :ram                     => 4295,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 1
        },
        {
          :id                      => 'c6id.xlarge',
          :name                    => 'c6id xLarge',
          :bits                    => 64,
          :cores                   => 4,
          :disk                    => 237,
          :ram                     => 8590,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 1
        },
        {
          :id                      => 'c6id.2xlarge',
          :name                    => 'c6id 2xLarge',
          :bits                    => 64,
          :cores                   => 8,
          :disk                    => 474,
          :ram                     => 17180,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 1
        },
        {
          :id                      => 'c6id.4xlarge',
          :name                    => 'c6id 4xLarge',
          :bits                    => 64,
          :cores                   => 16,
          :disk                    => 950,
          :ram                     => 34360,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 1
        },
        {
          :id                      => 'c6id.8xlarge',
          :name                    => 'c6id 8xLarge',
          :bits                    => 64,
          :cores                   => 32,
          :disk                    => 1900,
          :ram                     => 68719,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 1
        },
        {
          :id                      => 'c6id.12xlarge',
          :name                    => 'c6id Twelve Extra Large',
          :bits                    => 64,
          :cores                   => 48,
          :disk                    => 1425,
          :ram                     => 103079,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 2
        },
        {
          :id                      => 'c6id.16xlarge',
          :name                    => 'c6id 16xLarge',
          :bits                    => 64,
          :cores                   => 64,
          :disk                    => 1900,
          :ram                     => 137439,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 2
        },
        {
          :id                      => 'c6id.24xlarge',
          :name                    => 'c6id 24xLarge',
          :bits                    => 64,
          :cores                   => 96,
          :disk                    => 1425,
          :ram                     => 206158,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 4
        },
        {
          :id                      => 'c6id.32xlarge',
          :name                    => 'c6id 32xLarge',
          :bits                    => 64,
          :cores                   => 128,
          :disk                    => 1900,
          :ram                     => 274878,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 4
        },
        {
          :id                      => 'c6id.metal',
          :name                    => 'c6id metal',
          :bits                    => 64,
          :cores                   => 128,
          :disk                    => 1900,
          :ram                     => 274878,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 4
        },
        {
          :id                      => 'g2.2xlarge',
          :name                    => 'GPU Double Extra Large',
          :bits                    => 64,
          :cores                   => 8,
          :disk                    => 60,
          :ram                     => 16106,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 1
        },
        {
          :id                      => 'g2.8xlarge',
          :name                    => 'GPU Eight Extra Large',
          :bits                    => 64,
          :cores                   => 32,
          :disk                    => 240,
          :ram                     => 64424,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 2
        },
        {
          :id                      => 'hs1.8xlarge',
          :name                    => 'High Storage Eight Extra Large',
          :bits                    => 64,
          :cores                   => 16,
          :disk                    => 50331648,
          :ram                     => 125627,
          :ebs_optimized_available => false,
          :instance_store_volumes  => 24
        },
        {
          :id                      => 'm2.xlarge',
          :name                    => 'High-Memory Extra Large',
          :bits                    => 64,
          :cores                   => 2,
          :disk                    => 420,
          :ram                     => 18360,
          :ebs_optimized_available => false,
          :instance_store_volumes  => 1
        },
        {
          :id                      => 'm2.2xlarge',
          :name                    => 'High Memory Double Extra Large',
          :bits                    => 64,
          :cores                   => 4,
          :disk                    => 850,
          :ram                     => 36721,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 1
        },
        {
          :id                      => 'm2.4xlarge',
          :name                    => 'High Memory Quadruple Extra Large',
          :bits                    => 64,
          :cores                   => 8,
          :disk                    => 1690,
          :ram                     => 73443,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 2
        },
        {
          :id                      => 'cr1.8xlarge',
          :name                    => 'High Memory Eight Extra Large',
          :bits                    => 64,
          :cores                   => 32,
          :disk                    => 240,
          :ram                     => 261993,
          :ebs_optimized_available => false,
          :instance_store_volumes  => 2
        },
        {
          :id                      => 'm3.medium',
          :name                    => 'M3 Medium',
          :bits                    => 64,
          :cores                   => 1,
          :disk                    => 4,
          :ram                     => 4026,
          :ebs_optimized_available => false,
          :instance_store_volumes  => 1
        },
        {
          :id                      => 'm3.large',
          :name                    => 'M3 Large',
          :bits                    => 64,
          :cores                   => 2,
          :disk                    => 32,
          :ram                     => 8053,
          :ebs_optimized_available => false,
          :instance_store_volumes  => 1
        },
        {
          :id                      => 'm3.xlarge',
          :name                    => 'M3 Extra Large',
          :bits                    => 64,
          :cores                   => 4,
          :disk                    => 80,
          :ram                     => 16106,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 2
        },
        {
          :id                      => 'm3.2xlarge',
          :name                    => 'M3 Double Extra Large',
          :bits                    => 64,
          :cores                   => 8,
          :disk                    => 160,
          :ram                     => 32212,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 2
        },
        {
          :id                      => "hi1.4xlarge",
          :name                    => "High I/O Quadruple Extra Large Instance",
          :bits                    => 64,
          :cores                   =>  35,
          :disk                    => 2048,
          :ram                     => 61952,
          :ebs_optimized_available => false,
          :instance_store_volumes  => 2
        },
        {
          :id                      => 'cc1.4xlarge',
          :name                    => 'Cluster Compute Quadruple Extra Large',
          :bits                    => 64,
          :cores                   => 33.5,
          :disk                    => 1690,
          :ram                     => 23552,
          :ebs_optimized_available => false,
          :instance_store_volumes  => 0
        },
        {
          :id                      => 'cc2.8xlarge',
          :name                    => 'Cluster Compute Eight Extra Large',
          :bits                    => 64,
          :cores                   => 32,
          :disk                    => 3370,
          :ram                     => 64961,
          :ebs_optimized_available => false,
          :instance_store_volumes  => 4
        },
        {
          :id                      => 'cg1.4xlarge',
          :name                    => 'Cluster GPU Quadruple Extra Large',
          :bits                    => 64,
          :cores                   => 33.5,
          :disk                    => 1690,
          :ram                     => 22528,
          :ebs_optimized_available => false,
          :instance_store_volumes  => 2
        },
        {
          :id                      => 'i2.xlarge',
          :name                    => 'I2 Extra Large',
          :bits                    => 64,
          :cores                   => 4,
          :disk                    => 800,
          :ram                     => 32749,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 1
        },
        {
          :id                      => 'i2.2xlarge',
          :name                    => 'I2 Double Extra Large',
          :bits                    => 64,
          :cores                   => 8,
          :disk                    => 1600,
          :ram                     => 65498,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 2
        },
        {
          :id                      => 'i2.4xlarge',
          :name                    => 'I2 Quadruple Extra Large',
          :bits                    => 64,
          :cores                   => 16,
          :disk                    => 3200,
          :ram                     => 130996,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 4
        },
        {
          :id                      => 'i2.8xlarge',
          :name                    => 'I2 Eight Extra Large',
          :bits                    => 64,
          :cores                   => 32,
          :disk                    => 6400,
          :ram                     => 261993,
          :ebs_optimized_available => false,
          :instance_store_volumes  => 8
        },
        {
          :id                      => 'i3.large',
          :name                    => 'I3 Large',
          :bits                    => 64,
          :cores                   => 2,
          :disk                    => 475,
          :ram                     => 16374,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 1
        },
        {
          :id                      => 'i3.xlarge',
          :name                    => 'I3 Extra Large',
          :bits                    => 64,
          :cores                   => 4,
          :disk                    => 950,
          :ram                     => 32749,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 1
        },
        {
          :id                      => 'i3.2xlarge',
          :name                    => 'I3 Double Extra Large',
          :bits                    => 64,
          :cores                   => 8,
          :disk                    => 1900,
          :ram                     => 65498,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 1
        },
        {
          :id                      => 'i3.4xlarge',
          :name                    => 'I3 Quadruple Extra Large',
          :bits                    => 64,
          :cores                   => 16,
          :disk                    => 3800,
          :ram                     => 130996,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 2
        },
        {
          :id                      => 'i3.8xlarge',
          :name                    => 'I3 Eight Extra Large',
          :bits                    => 64,
          :cores                   => 32,
          :disk                    => 7600,
          :ram                     => 261993,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 4
        },
        {
          :id                      => 'i3.16xlarge',
          :name                    => 'I3 Sixteen Extra Large',
          :bits                    => 64,
          :cores                   => 64,
          :disk                    => 15200,
          :ram                     => 523986,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 8
        },
        {
          :id                      => 'i3.metal',
          :name                    => 'I3 Metal',
          :bits                    => 64,
          :cores                   => 72,
          :disk                    => 15200,
          :ram                     => 549756,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 8
        },
        {
          :id                      => 'i3en.large',
          :name                    => 'I3en Large',
          :bits                    => 64,
          :cores                   => 2,
          :disk                    => 1250,
          :ram                     => 17180,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 1
        },
        {
          :id                      => 'i3en.xlarge',
          :name                    => 'I3en Extra Large',
          :bits                    => 64,
          :cores                   => 4,
          :disk                    => 2500,
          :ram                     => 34360,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 1
        },
        {
          :id                      => 'i3en.2xlarge',
          :name                    => 'I3en Double Extra Large',
          :bits                    => 64,
          :cores                   => 8,
          :disk                    => 5000,
          :ram                     => 68719,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 2
        },
        {
          :id                      => 'i3en.3xlarge',
          :name                    => 'I3en Triple Extra Large',
          :bits                    => 64,
          :cores                   => 8,
          :disk                    => 7500,
          :ram                     => 103079,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 1
        },
        {
          :id                      => 'i3en.6xlarge',
          :name                    => 'I3en Sextuple Extra Large',
          :bits                    => 64,
          :cores                   => 24,
          :disk                    => 15000,
          :ram                     => 206158,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 2
        },
        {
          :id                      => 'i3en.12xlarge',
          :name                    => 'I3en Twelve Extra Large',
          :bits                    => 64,
          :cores                   => 24,
          :disk                    => 15000,
          :ram                     => 206158,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 2
        },
        {
          :id                      => 'i3en.16xlarge',
          :name                    => 'I3en Sixteen Extra Large',
          :bits                    => 64,
          :cores                   => 48,
          :disk                    => 30000,
          :ram                     => 412317,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 4
        },
        {
          :id                      => 'i3en.24xlarge',
          :name                    => 'I3en Twenty-four Extra Large',
          :bits                    => 64,
          :cores                   => 96,
          :disk                    => 60000,
          :ram                     => 824634,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 8
        },
        {
          :id                      => 'i3en.metal',
          :name                    => 'I3en Metal',
          :bits                    => 64,
          :cores                   => 96,
          :disk                    => 60000,
          :ram                     => 824634,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 8
        },
        {
          :id                      => "r3.large",
          :name                    => "R3 Large",
          :bits                    => 64,
          :cores                   => 2,
          :ram                     => 16374,
          :disk                    => 32,
          :ebs_optimized_available => false,
          :instance_store_volumes  => 1
        },
        {
          :id                      => "r3.xlarge",
          :name                    => "R3 Extra Large",
          :bits                    => 64,
          :cores                   => 4,
          :ram                     => 32749,
          :disk                    => 80,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 1
        },
        {
          :id                      => "r3.2xlarge",
          :name                    => "R3 Double Extra Large",
          :bits                    => 64,
          :cores                   => 8,
          :ram                     => 65498,
          :disk                    => 160,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 1
        },
        {
          :id                      => "r3.4xlarge",
          :name                    => "R3 Quadruple Extra Large",
          :bits                    => 64,
          :cores                   => 16,
          :ram                     => 130996,
          :disk                    => 320,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 1
        },
        {
          :id                      => "r3.8xlarge",
          :name                    => "R3 Eight Extra Large",
          :bits                    => 64,
          :cores                   => 32,
          :ram                     => 261993,
          :disk                    => 640,
          :ebs_optimized_available => false,
          :instance_store_volumes  => 2
        },
        {
          :id                      => "r4.large",
          :name                    => "R4 Large",
          :bits                    => 64,
          :cores                   => 2,
          :ram                     => 16374,
          :disk                    => 0,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 0
        },
        {
          :id                      => "r4.xlarge",
          :name                    => "R4 Extra Large",
          :bits                    => 64,
          :cores                   => 4,
          :ram                     => 32749,
          :disk                    => 0,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 0
        },
        {
          :id                      => "r4.2xlarge",
          :name                    => "R4 Double Extra Large",
          :bits                    => 64,
          :cores                   => 8,
          :ram                     => 65498,
          :disk                    => 0,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 0
        },
        {
          :id                      => "r4.4xlarge",
          :name                    => "R4 Quadruple Extra Large",
          :bits                    => 64,
          :cores                   => 16,
          :ram                     => 130996,
          :disk                    => 0,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 0
        },
        {
          :id                      => "r4.8xlarge",
          :name                    => "R4 Eight Extra Large",
          :bits                    => 64,
          :cores                   => 32,
          :ram                     => 261993,
          :disk                    => 0,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 0
        },
        {
          :id                      => "r4.16xlarge",
          :name                    => "R4 Sixteen Extra Large",
          :bits                    => 64,
          :cores                   => 64,
          :ram                     => 523986,
          :disk                    => 0,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 0
        },
        {
          :id                      => "r5.large",
          :name                    => "R5 Large",
          :bits                    => 64,
          :cores                   => 2,
          :ram                     => 17179,
          :disk                    => 0,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 0
        },
        {
          :id                      => "r5.xlarge",
          :name                    => "R5 Extra Large",
          :bits                    => 64,
          :cores                   => 4,
          :ram                     => 34359,
          :disk                    => 0,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 0
        },
        {
          :id                      => "r5.2xlarge",
          :name                    => "R5 Double Extra Large",
          :bits                    => 64,
          :cores                   => 8,
          :ram                     => 68719,
          :disk                    => 0,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 0
        },
        {
          :id                      => "r5.4xlarge",
          :name                    => "R5 Quadruple Extra Large",
          :bits                    => 64,
          :cores                   => 16,
          :ram                     => 137438,
          :disk                    => 0,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 0
        },
        {
          :id                      => "r5.8xlarge",
          :name                    => "R5 Octuple Extra Large",
          :bits                    => 64,
          :cores                   => 32,
          :ram                     => 274878,
          :disk                    => 0,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 0
        },
        {
          :id                      => "r5.12xlarge",
          :name                    => "R5 Twelve Extra Large",
          :bits                    => 64,
          :cores                   => 48,
          :ram                     => 412316,
          :disk                    => 0,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 0
        },
        {
          :id                      => "r5.16xlarge",
          :name                    => "R5 Sixteen Extra Large",
          :bits                    => 64,
          :cores                   => 64,
          :ram                     => 549756,
          :disk                    => 0,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 0
        },
        {
          :id                      => "r5.24xlarge",
          :name                    => "R5 Twenty Four Extra Large",
          :bits                    => 64,
          :cores                   => 96,
          :ram                     => 824633,
          :disk                    => 0,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 0
        },
        {
          :id                      => "r5.metal",
          :name                    => "R5 Metal",
          :bits                    => 64,
          :cores                   => 96,
          :ram                     => 824633,
          :disk                    => 0,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 0
        },
        {
          :id                      => "r5d.large",
          :name                    => "R5d Large",
          :bits                    => 64,
          :cores                   => 2,
          :ram                     => 17179,
          :disk                    => 75,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 1
        },
        {
          :id                      => "r5d.xlarge",
          :name                    => "R5d Extra Large",
          :bits                    => 64,
          :cores                   => 4,
          :ram                     => 34359,
          :disk                    => 150,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 1
        },
        {
          :id                      => "r5d.2xlarge",
          :name                    => "R5d Double Extra Large",
          :bits                    => 64,
          :cores                   => 8,
          :ram                     => 68719,
          :disk                    => 300,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 1
        },
        {
          :id                      => "r5d.4xlarge",
          :name                    => "R5d Quadruple Extra Large",
          :bits                    => 64,
          :cores                   => 16,
          :ram                     => 137438,
          :disk                    => 600,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 2
        },
        {
          :id                      => "r5d.8xlarge",
          :name                    => "R5d Octuple Extra Large",
          :bits                    => 64,
          :cores                   => 16,
          :ram                     => 137438,
          :disk                    => 600,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 2
        },
        {
          :id                      => "r5d.12xlarge",
          :name                    => "R5d Twelve Extra Large",
          :bits                    => 64,
          :cores                   => 48,
          :ram                     => 412316,
          :disk                    => 1800,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 2
        },
        {
          :id                      => "r5d.16xlarge",
          :name                    => "R5d Sixteen Extra Large",
          :bits                    => 64,
          :cores                   => 64,
          :ram                     => 549756,
          :disk                    => 2400,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 4
        },
        {
          :id                      => "r5d.24xlarge",
          :name                    => "R5d Twenty Four Extra Large",
          :bits                    => 64,
          :cores                   => 96,
          :ram                     => 824633,
          :disk                    => 3600,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 4
        },
        {
          :id                      => "r5d.metal",
          :name                    => "R5d Metal",
          :bits                    => 64,
          :cores                   => 96,
          :ram                     => 824633,
          :disk                    => 3600,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 4
        },
        {
          :id                      => "r5a.large",
          :name                    => "R5 (AMD) Large",
          :bits                    => 64,
          :cores                   => 2,
          :ram                     => 17179,
          :disk                    => 0,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 0
        },
        {
          :id                      => "r5a.xlarge",
          :name                    => "R5 (AMD) Extra Large",
          :bits                    => 64,
          :cores                   => 4,
          :ram                     => 34359,
          :disk                    => 0,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 0
        },
        {
          :id                      => "r5a.2xlarge",
          :name                    => "R5 (AMD) Double Extra Large",
          :bits                    => 64,
          :cores                   => 8,
          :ram                     => 68719,
          :disk                    => 0,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 0
        },
        {
          :id                      => "r5a.4xlarge",
          :name                    => "R5 (AMD) Quadruple Extra Large",
          :bits                    => 64,
          :cores                   => 16,
          :ram                     => 137438,
          :disk                    => 0,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 0
        },
        {
          :id                      => "r5a.12xlarge",
          :name                    => "R5 (AMD) Twelve Extra Large",
          :bits                    => 64,
          :cores                   => 48,
          :ram                     => 412316,
          :disk                    => 0,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 0
        },
        {
          :id                      => "r5a.24xlarge",
          :name                    => "R5 (AMD) Twenty Four Extra Large",
          :bits                    => 64,
          :cores                   => 96,
          :ram                     => 824633,
          :disk                    => 0,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 0
        },
        {
          :id                      => "r5ad.large",
          :name                    => "R5d (AMD) Large",
          :bits                    => 64,
          :cores                   => 2,
          :ram                     => 17179,
          :disk                    => 75,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 1
        },
        {
          :id                      => "r5ad.xlarge",
          :name                    => "R5d (AMD) Extra Large",
          :bits                    => 64,
          :cores                   => 4,
          :ram                     => 34359,
          :disk                    => 150,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 1
        },
        {
          :id                      => "r5ad.2xlarge",
          :name                    => "R5d (AMD) Double Extra Large",
          :bits                    => 64,
          :cores                   => 8,
          :ram                     => 68719,
          :disk                    => 300,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 1
        },
        {
          :id                      => "r5ad.4xlarge",
          :name                    => "R5d (AMD) Quadruple Extra Large",
          :bits                    => 64,
          :cores                   => 16,
          :ram                     => 137438,
          :disk                    => 600,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 2
        },
        {
          :id                      => "r5ad.12xlarge",
          :name                    => "R5d (AMD) Twelve Extra Large",
          :bits                    => 64,
          :cores                   => 48,
          :ram                     => 412316,
          :disk                    => 1800,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 2
        },
        {
          :id                      => "r5ad.24xlarge",
          :name                    => "R5d (AMD) Twenty Four Extra Large",
          :bits                    => 64,
          :cores                   => 96,
          :ram                     => 824633,
          :disk                    => 3600,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 4
        },
        {
          :id                      => "r5n.large",
          :name                    => "R5n Large",
          :bits                    => 64,
          :cores                   => 2,
          :ram                     => 17179,
          :disk                    => 0,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 0
        },
        {
          :id                      => "r5n.xlarge",
          :name                    => "R5n Extra Large",
          :bits                    => 64,
          :cores                   => 4,
          :ram                     => 34359,
          :disk                    => 0,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 0
        },
        {
          :id                      => "r5n.2xlarge",
          :name                    => "R5n Double Extra Large",
          :bits                    => 64,
          :cores                   => 8,
          :ram                     => 68719,
          :disk                    => 0,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 0
        },
        {
          :id                      => "r5n.4xlarge",
          :name                    => "R5n Quadruple Extra Large",
          :bits                    => 64,
          :cores                   => 16,
          :ram                     => 137438,
          :disk                    => 0,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 0
        },
        {
          :id                      => "r5n.8xlarge",
          :name                    => "R5n Octuple Extra Large",
          :bits                    => 64,
          :cores                   => 32,
          :ram                     => 274878,
          :disk                    => 0,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 0
        },
        {
          :id                      => "r5n.12xlarge",
          :name                    => "R5n Twelve Extra Large",
          :bits                    => 64,
          :cores                   => 48,
          :ram                     => 412316,
          :disk                    => 0,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 0
        },
        {
          :id                      => "r5n.16xlarge",
          :name                    => "R5n Sixteen Extra Large",
          :bits                    => 64,
          :cores                   => 64,
          :ram                     => 549756,
          :disk                    => 0,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 0
        },
        {
          :id                      => "r5n.24xlarge",
          :name                    => "R5n Twenty Four Extra Large",
          :bits                    => 64,
          :cores                   => 96,
          :ram                     => 824633,
          :disk                    => 0,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 0
        },
        {
          :id                      => "r5dn.large",
          :name                    => "R5dn Large",
          :bits                    => 64,
          :cores                   => 2,
          :ram                     => 17179,
          :disk                    => 75,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 1
        },
        {
          :id                      => "r5dn.xlarge",
          :name                    => "R5dn Extra Large",
          :bits                    => 64,
          :cores                   => 4,
          :ram                     => 34359,
          :disk                    => 150,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 1
        },
        {
          :id                      => "r5dn.2xlarge",
          :name                    => "R5dn Double Extra Large",
          :bits                    => 64,
          :cores                   => 8,
          :ram                     => 68719,
          :disk                    => 300,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 1
        },
        {
          :id                      => "r5dn.4xlarge",
          :name                    => "R5dn Quadruple Extra Large",
          :bits                    => 64,
          :cores                   => 16,
          :ram                     => 137438,
          :disk                    => 600,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 2
        },
        {
          :id                      => "r5dn.8xlarge",
          :name                    => "R5dn Octuple Extra Large",
          :bits                    => 64,
          :cores                   => 32,
          :ram                     => 274878,
          :disk                    => 1200,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 2
        },
        {
          :id                      => "r5dn.12xlarge",
          :name                    => "R5dn Twelve Extra Large",
          :bits                    => 64,
          :cores                   => 48,
          :ram                     => 412316,
          :disk                    => 1800,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 2
        },
        {
          :id                      => "r5dn.16xlarge",
          :name                    => "R5dn Sixteen Extra Large",
          :bits                    => 64,
          :cores                   => 64,
          :ram                     => 549756,
          :disk                    => 2400,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 4
        },
        {
          :id                      => "r5dn.24xlarge",
          :name                    => "R5dn Twenty Four Extra Large",
          :bits                    => 64,
          :cores                   => 96,
          :ram                     => 824633,
          :disk                    => 3600,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 4
        },
        {
          :id                      => 'r6g.medium',
          :name                    => 'R6G Medium',
          :bits                    => 64,
          :cores                   => 1,
          :disk                    => 0,
          :ram                     => 8590,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 0
        },
        {
          :id                      => 'r6g.large',
          :name                    => 'R6G Large',
          :bits                    => 64,
          :cores                   => 2,
          :disk                    => 0,
          :ram                     => 17180,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 0
        },
        {
          :id                      => 'r6g.xlarge',
          :name                    => 'R6G Extra Large',
          :bits                    => 64,
          :cores                   => 4,
          :disk                    => 0,
          :ram                     => 34360,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 0
        },
        {
          :id                      => 'r6g.2xlarge',
          :name                    => 'R6G Double Extra Large',
          :bits                    => 64,
          :cores                   => 8,
          :disk                    => 0,
          :ram                     => 68719,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 0
        },
        {
          :id                      => 'r6g.4xlarge',
          :name                    => 'R6G Quadruple Extra Large',
          :bits                    => 64,
          :cores                   => 16,
          :disk                    => 0,
          :ram                     => 137439,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 0
        },
        {
          :id                      => 'r6g.8xlarge',
          :name                    => 'R6G Octuple Extra Large',
          :bits                    => 64,
          :cores                   => 32,
          :disk                    => 0,
          :ram                     => 274878,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 0
        },
        {
          :id                      => 'r6g.12xlarge',
          :name                    => 'R6G Twelve Extra Large',
          :bits                    => 64,
          :cores                   => 48,
          :disk                    => 0,
          :ram                     => 412317,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 0
        },
        {
          :id                      => 'r6g.16xlarge',
          :name                    => 'R6G Sixteen Extra Large',
          :bits                    => 64,
          :cores                   => 64,
          :disk                    => 0,
          :ram                     => 549756,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 0
        },
        {
          :id                      => 'r6g.metal',
          :name                    => 'R6G Metal',
          :bits                    => 64,
          :cores                   => 64,
          :disk                    => 0,
          :ram                     => 549756,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 0
        },
        {
          :id                      => 'r6gd.medium',
          :name                    => 'R6GD Medium',
          :bits                    => 64,
          :cores                   => 1,
          :disk                    => 59,
          :ram                     => 8590,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 1
        },
        {
          :id                      => 'r6gd.large',
          :name                    => 'R6GD Large',
          :bits                    => 64,
          :cores                   => 2,
          :disk                    => 118,
          :ram                     => 17180,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 1
        },
        {
          :id                      => 'r6gd.xlarge',
          :name                    => 'R6GD Extra Large',
          :bits                    => 64,
          :cores                   => 4,
          :disk                    => 237,
          :ram                     => 34360,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 1
        },
        {
          :id                      => 'r6gd.2xlarge',
          :name                    => 'R6GD Double Extra Large',
          :bits                    => 64,
          :cores                   => 8,
          :disk                    => 474,
          :ram                     => 68719,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 1
        },
        {
          :id                      => 'r6gd.4xlarge',
          :name                    => 'R6GD Quadruple Extra Large',
          :bits                    => 64,
          :cores                   => 16,
          :disk                    => 950,
          :ram                     => 137439,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 1
        },
        {
          :id                      => 'r6gd.8xlarge',
          :name                    => 'R6GD Octuple Extra Large',
          :bits                    => 64,
          :cores                   => 32,
          :disk                    => 1900,
          :ram                     => 274878,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 1
        },
        {
          :id                      => 'r6gd.12xlarge',
          :name                    => 'R6GD Twelve Extra Large',
          :bits                    => 64,
          :cores                   => 48,
          :disk                    => 2850,
          :ram                     => 412317,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 2
        },
        {
          :id                      => 'r6gd.16xlarge',
          :name                    => 'R6GD Sixteen Extra Large',
          :bits                    => 64,
          :cores                   => 64,
          :disk                    => 3800,
          :ram                     => 549756,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 2
        },
        {
          :id                      => 'r6gd.metal',
          :name                    => 'R6GD Metal',
          :bits                    => 64,
          :cores                   => 64,
          :disk                    => 3800,
          :ram                     => 549756,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 2
        },
        {
          :id                      => "r6a.large",
          :name                    => "r6a Large",
          :bits                    => 64,
          :cores                   => 2,
          :ram                     => 17179,
          :disk                    => 0,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 0
        },
        {
          :id                      => "r6a.xlarge",
          :name                    => "r6a Extra Large",
          :bits                    => 64,
          :cores                   => 4,
          :ram                     => 34359,
          :disk                    => 0,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 0
        },
        {
          :id                      => "r6a.2xlarge",
          :name                    => "r6a Double Extra Large",
          :bits                    => 64,
          :cores                   => 8,
          :ram                     => 68719,
          :disk                    => 0,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 0
        },
        {
          :id                      => "r6a.4xlarge",
          :name                    => "r6a Quadruple Extra Large",
          :bits                    => 64,
          :cores                   => 16,
          :ram                     => 137438,
          :disk                    => 0,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 0
        },
        {
          :id                      => "r6a.8xlarge",
          :name                    => "r6a Octuple Extra Large",
          :bits                    => 64,
          :cores                   => 32,
          :ram                     => 274878,
          :disk                    => 0,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 0
        },
        {
          :id                      => "r6a.12xlarge",
          :name                    => "r6a Twelve Extra Large",
          :bits                    => 64,
          :cores                   => 48,
          :ram                     => 412316,
          :disk                    => 0,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 0
        },
        {
          :id                      => "r6a.16xlarge",
          :name                    => "r6a Sixteen Extra Large",
          :bits                    => 64,
          :cores                   => 64,
          :ram                     => 549756,
          :disk                    => 0,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 0
        },
        {
          :id                      => "r6a.24xlarge",
          :name                    => "r6a Twenty Four Extra Large",
          :bits                    => 64,
          :cores                   => 96,
          :ram                     => 824633,
          :disk                    => 0,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 0
        },
        {
          :id                      => "r6a.32xlarge",
          :name                    => "r6a Thirty Two Extra Large",
          :bits                    => 64,
          :cores                   => 128,
          :ram                     => 1099512,
          :disk                    => 0,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 0
        },
        {
          :id                      => "r6a.48xlarge",
          :name                    => "r6a Forty Eight Extra Large",
          :bits                    => 64,
          :cores                   => 192,
          :ram                     => 1649268,
          :disk                    => 0,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 0
        },
        {
          :id                      => "r6a.metal",
          :name                    => "r6a metal",
          :bits                    => 64,
          :cores                   => 192,
          :ram                     => 1649268,
          :disk                    => 0,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 0
        },
        {
          :id                      => "r6i.large",
          :name                    => "r6i Large",
          :bits                    => 64,
          :cores                   => 2,
          :ram                     => 17179,
          :disk                    => 0,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 0
        },
        {
          :id                      => "r6i.xlarge",
          :name                    => "r6i Extra Large",
          :bits                    => 64,
          :cores                   => 4,
          :ram                     => 34359,
          :disk                    => 0,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 0
        },
        {
          :id                      => "r6i.2xlarge",
          :name                    => "r6i Double Extra Large",
          :bits                    => 64,
          :cores                   => 8,
          :ram                     => 68719,
          :disk                    => 0,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 0
        },
        {
          :id                      => "r6i.4xlarge",
          :name                    => "r6i Quadruple Extra Large",
          :bits                    => 64,
          :cores                   => 16,
          :ram                     => 137438,
          :disk                    => 0,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 0
        },
        {
          :id                      => "r6i.8xlarge",
          :name                    => "r6i Octuple Extra Large",
          :bits                    => 64,
          :cores                   => 32,
          :ram                     => 274878,
          :disk                    => 0,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 0
        },
        {
          :id                      => "r6i.12xlarge",
          :name                    => "r6i Twelve Extra Large",
          :bits                    => 64,
          :cores                   => 48,
          :ram                     => 412316,
          :disk                    => 0,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 0
        },
        {
          :id                      => "r6i.16xlarge",
          :name                    => "r6i Sixteen Extra Large",
          :bits                    => 64,
          :cores                   => 64,
          :ram                     => 549756,
          :disk                    => 0,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 0
        },
        {
          :id                      => "r6i.24xlarge",
          :name                    => "r6i Twenty Four Extra Large",
          :bits                    => 64,
          :cores                   => 96,
          :ram                     => 824633,
          :disk                    => 0,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 0
        },
        {
          :id                      => "r6i.32xlarge",
          :name                    => "r6i Thirty Two Extra Large",
          :bits                    => 64,
          :cores                   => 128,
          :ram                     => 1099512,
          :disk                    => 0,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 0
        },
        {
          :id                      => "r6i.metal",
          :name                    => "r6i metal",
          :bits                    => 64,
          :cores                   => 128,
          :ram                     => 1099512,
          :disk                    => 0,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 0
        },
        {
          :id                      => "r6id.large",
          :name                    => "r6id Large",
          :bits                    => 64,
          :cores                   => 2,
          :ram                     => 17179,
          :disk                    => 118,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 1
        },
        {
          :id                      => "r6id.xlarge",
          :name                    => "r6id Extra Large",
          :bits                    => 64,
          :cores                   => 4,
          :ram                     => 34359,
          :disk                    => 237,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 1
        },
        {
          :id                      => "r6id.2xlarge",
          :name                    => "r6id Double Extra Large",
          :bits                    => 64,
          :cores                   => 8,
          :ram                     => 68719,
          :disk                    => 474,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 1
        },
        {
          :id                      => "r6id.4xlarge",
          :name                    => "r6id Quadruple Extra Large",
          :bits                    => 64,
          :cores                   => 16,
          :ram                     => 137438,
          :disk                    => 950,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 1
        },
        {
          :id                      => "r6id.8xlarge",
          :name                    => "r6id Octuple Extra Large",
          :bits                    => 64,
          :cores                   => 32,
          :ram                     => 274878,
          :disk                    => 1900,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 1
        },
        {
          :id                      => "r6id.12xlarge",
          :name                    => "r6id Twelve Extra Large",
          :bits                    => 64,
          :cores                   => 48,
          :ram                     => 412316,
          :disk                    => 1425,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 2
        },
        {
          :id                      => "r6id.16xlarge",
          :name                    => "r6id Sixteen Extra Large",
          :bits                    => 64,
          :cores                   => 64,
          :ram                     => 549756,
          :disk                    => 1900,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 2
        },
        {
          :id                      => "r6id.24xlarge",
          :name                    => "r6id Twenty Four Extra Large",
          :bits                    => 64,
          :cores                   => 96,
          :ram                     => 824633,
          :disk                    => 1425,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 4
        },
        {
          :id                      => "r6id.32xlarge",
          :name                    => "r6id Thirty Two Extra Large",
          :bits                    => 64,
          :cores                   => 128,
          :ram                     => 1099512,
          :disk                    => 1900,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 4
        },
        {
          :id                      => "r6id.metal",
          :name                    => "r6id metal",
          :bits                    => 64,
          :cores                   => 128,
          :ram                     => 1099512,
          :disk                    => 1900,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 4
        },
        {
          :id                      => "x1.16xlarge",
          :name                    => "X1 Sixteen Extra Large",
          :bits                    => 64,
          :cores                   => 64,
          :ram                     => 1047972,
          :disk                    => 1920,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 1
        },
        {
          :id                      => "x1.32xlarge",
          :name                    => "X1 Thirty-two Extra Large",
          :bits                    => 64,
          :cores                   => 128,
          :ram                     => 2095944,
          :disk                    => 3840,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 2
        },
        {
          :id                      => "x1e.xlarge",
          :name                    => "X1e Extra Large",
          :bits                    => 64,
          :cores                   => 4,
          :ram                     => 130997,
          :disk                    => 120,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 1
        },
        {
          :id                      => "x1e.2xlarge",
          :name                    => "X1e Double Extra Large",
          :bits                    => 64,
          :cores                   => 8,
          :ram                     => 261993,
          :disk                    => 240,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 1
        },
        {
          :id                      => "x1e.4xlarge",
          :name                    => "X1e Quadruple Extra Large",
          :bits                    => 64,
          :cores                   => 16,
          :ram                     => 523986,
          :disk                    => 480,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 1
        },
        {
          :id                      => "x1e.8xlarge",
          :name                    => "X1e Octuple Extra Large",
          :bits                    => 64,
          :cores                   => 32,
          :ram                     => 1043677,
          :disk                    => 960,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 1
        },
        {
          :id                      => "x1e.16xlarge",
          :name                    => "X1e Sixteen Extra Large",
          :bits                    => 64,
          :cores                   => 64,
          :ram                     => 2095944,
          :disk                    => 1920,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 1
        },
        {
          :id                      => "x1e.32xlarge",
          :name                    => "X1e Thirty-two Extra Large",
          :bits                    => 64,
          :cores                   => 128,
          :ram                     => 3118147,
          :disk                    => 3840,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 2
        },
        {
          :id                      => 'x2gd.medium',
          :name                    => 'X2gd Medium Instance',
          :bits                    => 64,
          :cores                   => 1,
          :disk                    => 59,
          :ram                     => 17180,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 0
        },
        {
          :id                      => 'x2gd.large',
          :name                    => 'X2gd Large Instance',
          :bits                    => 64,
          :cores                   => 2,
          :disk                    => 118,
          :ram                     => 34360,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 0
        },
        {
          :id                      => 'x2gd.xlarge',
          :name                    => 'X2gd Extra Large Instance',
          :bits                    => 64,
          :cores                   => 4,
          :disk                    => 237,
          :ram                     => 68719,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 0
        },
        {
          :id                      => 'x2gd.2xlarge',
          :name                    => 'X2gd Double Extra Large Instance',
          :bits                    => 64,
          :cores                   => 8,
          :disk                    => 475,
          :ram                     => 137439,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 0
        },
        {
          :id                      => 'x2gd.4xlarge',
          :name                    => 'X2gd Quadruple Extra Large Instance',
          :bits                    => 64,
          :cores                   => 16,
          :disk                    => 950,
          :ram                     => 274878,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 0
        },
        {
          :id                      => 'x2gd.8xlarge',
          :name                    => 'X2gd Octuple Extra Large Instance',
          :bits                    => 64,
          :cores                   => 32,
          :disk                    => 1900,
          :ram                     => 549756,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 0
        },
        {
          :id                      => 'x2gd.12xlarge',
          :name                    => 'X2gd Twelve Extra Large Instance',
          :bits                    => 64,
          :cores                   => 48,
          :disk                    => 2850,
          :ram                     => 824634,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 0
        },
        {
          :id                      => 'x2gd.16xlarge',
          :name                    => 'X2gd Sixteen Extra Large Instance',
          :bits                    => 64,
          :cores                   => 64,
          :disk                    => 3800,
          :ram                     => 1099512,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 0
        },
        {
          :id                      => 'x2gd.metal',
          :name                    => 'X2gd Metal',
          :bits                    => 64,
          :cores                   => 64,
          :disk                    => 3800,
          :ram                     => 1099512,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 0
        },
        {
          :id                      => "u-6tb1.metal",
          :name                    => "U 6TB Metal",
          :bits                    => 64,
          :cores                   => 448,
          :ram                     => 6597071,
          :disk                    => 0,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 0
        },
        {
          :id                      => "u-9tb1.metal",
          :name                    => "U 9 TB Metal",
          :bits                    => 64,
          :cores                   => 448,
          :ram                     => 9895606,
          :disk                    => 0,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 0
        },
        {
          :id                      => "u-12tb1.metal",
          :name                    => "U 12 TB Metal",
          :bits                    => 64,
          :cores                   => 448,
          :ram                     => 13194141,
          :disk                    => 0,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 0
        },
        {
          :id                      => "u-18tb1.metal",
          :name                    => "U 18 TB Metal",
          :bits                    => 64,
          :cores                   => 448,
          :ram                     => 19791212,
          :disk                    => 0,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 0
        },
        {
          :id                      => "u-24tb1.metal",
          :name                    => "U 24 TB Metal",
          :bits                    => 64,
          :cores                   => 448,
          :ram                     => 26388283,
          :disk                    => 0,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 0
        },
        {
          :id                      => "z1d.large",
          :name                    => "Z1d Large",
          :bits                    => 64,
          :cores                   => 2,
          :ram                     => 17180,
          :disk                    => 75,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 1
        },
        {
          :id                      => "z1d.xlarge",
          :name                    => "Z1d Extra Large",
          :bits                    => 64,
          :cores                   => 4,
          :ram                     => 34359,
          :disk                    => 150,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 1
        },
        {
          :id                      => "z1d.2xlarge",
          :name                    => "Z1d Double Extra Large",
          :bits                    => 64,
          :cores                   => 8,
          :ram                     => 68719,
          :disk                    => 300,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 1
        },
        {
          :id                      => "z1d.3xlarge",
          :name                    => "Z1d Triple Extra Large",
          :bits                    => 64,
          :cores                   => 12,
          :ram                     => 103079,
          :disk                    => 450,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 1
        },
        {
          :id                      => "z1d.6xlarge",
          :name                    => "Z1d Sextuple Large",
          :bits                    => 64,
          :cores                   => 24,
          :ram                     => 206158,
          :disk                    => 900,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 1
        },
        {
          :id                      => "z1d.12xlarge",
          :name                    => "Z1d Twelve Extra Large",
          :bits                    => 64,
          :cores                   => 48,
          :ram                     => 412316,
          :disk                    => 1800,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 2
        },
        {
          :id                      => "z1d.metal",
          :name                    => "Z1d Metal",
          :bits                    => 64,
          :cores                   => 48,
          :ram                     => 412316,
          :disk                    => 1800,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 2
        },
        {
          :id                      => "d2.xlarge",
          :name                    => "D2 Extra Large",
          :bits                    => 64,
          :cores                   => 4,
          :ram                     => 32749,
          :disk                    => 6000,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 3
        },
        {
          :id                      => "d2.2xlarge",
          :name                    => "D2 Double Extra Large",
          :bits                    => 64,
          :cores                   => 8,
          :ram                     => 65498,
          :disk                    => 12000,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 6
        },
        {
          :id                      => "d2.4xlarge",
          :name                    => "D2 Quadruple Extra Large",
          :bits                    => 64,
          :cores                   => 16,
          :ram                     => 130996,
          :disk                    => 24000,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 12
        },
        {
          :id                      => "d2.8xlarge",
          :name                    => "D2 Eight Extra Large",
          :bits                    => 64,
          :cores                   => 36,
          :ram                     => 261993,
          :disk                    => 48000,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 24
        },
        {
          :id                      => "h1.2xlarge",
          :name                    => "H1 Double Extra Large",
          :bits                    => 64,
          :cores                   => 8,
          :ram                     => 34360,
          :disk                    => 2000,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 1
        },
        {
          :id                      => "h1.4xlarge",
          :name                    => "H1 Quadruple Extra Large",
          :bits                    => 64,
          :cores                   => 16,
          :ram                     => 68719,
          :disk                    => 4000,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 2
        },
        {
          :id                      => "h1.8xlarge",
          :name                    => "H1 Octuple Extra Large",
          :bits                    => 64,
          :cores                   => 32,
          :ram                     => 137439,
          :disk                    => 8000,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 4
        },
        {
          :id                      => "h1.16xlarge",
          :name                    => "H1 Sixteen Extra Large",
          :bits                    => 64,
          :cores                   => 64,
          :ram                     => 274878,
          :disk                    => 16000,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 8
        },
        {
          :id                      => "m4.large",
          :name                    => "M4 Large",
          :bits                    => 64,
          :cores                   => 2,
          :ram                     => 8589,
          :disk                    => 0,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 0
        },
        {
          :id                      => "m4.xlarge",
          :name                    => "M4 Extra Large",
          :bits                    => 64,
          :cores                   => 4,
          :ram                     => 17179,
          :disk                    => 0,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 0
        },
        {
          :id                      => "m4.2xlarge",
          :name                    => "M4 Double Extra Large",
          :bits                    => 64,
          :cores                   => 8,
          :ram                     => 34359,
          :disk                    => 0,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 0
        },
        {
          :id                      => "m4.4xlarge",
          :name                    => "M4 Quadruple Extra Large",
          :bits                    => 64,
          :cores                   => 16,
          :ram                     => 68719,
          :disk                    => 0,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 0
        },
        {
          :id                      => "m4.10xlarge",
          :name                    => "M4 Ten Extra Large",
          :bits                    => 64,
          :cores                   => 40,
          :ram                     => 171798,
          :disk                    => 0,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 0
        },
        {
          :id                      => "m4.16xlarge",
          :name                    => "M4 Sixteen Extra Large",
          :bits                    => 64,
          :cores                   => 64,
          :ram                     => 262144,
          :disk                    => 0,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 0
        },
        {
          :id                      => "m5.large",
          :name                    => "M5 Large",
          :bits                    => 64,
          :cores                   => 2,
          :ram                     => 8589,
          :disk                    => 0,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 0
        },
        {
          :id                      => "m5.xlarge",
          :name                    => "M5 Extra Large",
          :bits                    => 64,
          :cores                   => 4,
          :ram                     => 17179,
          :disk                    => 0,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 0
        },
        {
          :id                      => "m5.2xlarge",
          :name                    => "M5 Double Extra Large",
          :bits                    => 64,
          :cores                   => 8,
          :ram                     => 34359,
          :disk                    => 0,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 0
        },
        {
          :id                      => "m5.4xlarge",
          :name                    => "M5 Quadruple Extra Large",
          :bits                    => 64,
          :cores                   => 16,
          :ram                     => 68719,
          :disk                    => 0,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 0
        },
        {
          :id                      => "m5.8xlarge",
          :name                    => "M5 Octuple Extra Large",
          :bits                    => 64,
          :cores                   => 32,
          :ram                     => 137439,
          :disk                    => 0,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 0
        },
        {
          :id                      => "m5.12xlarge",
          :name                    => "M5 Twelve Extra Large",
          :bits                    => 64,
          :cores                   => 48,
          :ram                     => 206158,
          :disk                    => 0,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 0
        },
        {
          :id                      => "m5.16xlarge",
          :name                    => "M5 Sixteen Extra Large",
          :bits                    => 64,
          :cores                   => 64,
          :ram                     => 274878,
          :disk                    => 0,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 0
        },
        {
          :id                      => "m5.24xlarge",
          :name                    => "M5 Twenty Four Extra Large",
          :bits                    => 64,
          :cores                   => 96,
          :ram                     => 412316,
          :disk                    => 0,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 0
        },
        {
          :id                      => "m5.metal",
          :name                    => "M5 Metal",
          :bits                    => 64,
          :cores                   => 96,
          :ram                     => 412316,
          :disk                    => 0,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 0
        },
        {
          :id                      => "m6a.large",
          :name                    => "m6a Large",
          :bits                    => 64,
          :cores                   => 2,
          :ram                     => 8589,
          :disk                    => 0,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 0
        },
        {
          :id                      => "m6a.xlarge",
          :name                    => "m6a Extra Large",
          :bits                    => 64,
          :cores                   => 4,
          :ram                     => 17179,
          :disk                    => 0,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 0
        },
        {
          :id                      => "m6a.2xlarge",
          :name                    => "m6a Double Extra Large",
          :bits                    => 64,
          :cores                   => 8,
          :ram                     => 34359,
          :disk                    => 0,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 0
        },
        {
          :id                      => "m6a.4xlarge",
          :name                    => "m6a Quadruple Extra Large",
          :bits                    => 64,
          :cores                   => 16,
          :ram                     => 68719,
          :disk                    => 0,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 0
        },
        {
          :id                      => "m6a.8xlarge",
          :name                    => "m6a Octuple Extra Large",
          :bits                    => 64,
          :cores                   => 32,
          :ram                     => 137439,
          :disk                    => 0,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 0
        },
        {
          :id                      => "m6a.12xlarge",
          :name                    => "m6a Twelve Extra Large",
          :bits                    => 64,
          :cores                   => 48,
          :ram                     => 206158,
          :disk                    => 0,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 0
        },
        {
          :id                      => "m6a.16xlarge",
          :name                    => "m6a Sixteen Extra Large",
          :bits                    => 64,
          :cores                   => 64,
          :ram                     => 274878,
          :disk                    => 0,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 0
        },
        {
          :id                      => "m6a.24xlarge",
          :name                    => "m6a Twenty Four Extra Large",
          :bits                    => 64,
          :cores                   => 96,
          :ram                     => 412316,
          :disk                    => 0,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 0
        },
        {
          :id                      => "m6a.32xlarge",
          :name                    => "m6a Thirty Two Extra Large",
          :bits                    => 64,
          :cores                   => 128,
          :ram                     => 549756,
          :disk                    => 0,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 0
        },
        {
          :id                      => "m6a.48xlarge",
          :name                    => "m6a Fourty Eight Extra Large",
          :bits                    => 64,
          :cores                   => 192,
          :ram                     => 824634,
          :disk                    => 0,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 0
        },
        {
          :id                      => "m6a.metal",
          :name                    => "m6a Metal",
          :bits                    => 64,
          :cores                   => 192,
          :ram                     => 824634,
          :disk                    => 0,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 0
        },
        {
          :id                      => "m6i.large",
          :name                    => "m6i Large",
          :bits                    => 64,
          :cores                   => 2,
          :ram                     => 8589,
          :disk                    => 0,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 0
        },
        {
          :id                      => "m6i.xlarge",
          :name                    => "m6i Extra Large",
          :bits                    => 64,
          :cores                   => 4,
          :ram                     => 17179,
          :disk                    => 0,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 0
        },
        {
          :id                      => "m6i.2xlarge",
          :name                    => "m6i Double Extra Large",
          :bits                    => 64,
          :cores                   => 8,
          :ram                     => 34359,
          :disk                    => 0,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 0
        },
        {
          :id                      => "m6i.4xlarge",
          :name                    => "m6i Quadruple Extra Large",
          :bits                    => 64,
          :cores                   => 16,
          :ram                     => 68719,
          :disk                    => 0,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 0
        },
        {
          :id                      => "m6i.8xlarge",
          :name                    => "m6i Octuple Extra Large",
          :bits                    => 64,
          :cores                   => 32,
          :ram                     => 137439,
          :disk                    => 0,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 0
        },
        {
          :id                      => "m6i.12xlarge",
          :name                    => "m6i Twelve Extra Large",
          :bits                    => 64,
          :cores                   => 48,
          :ram                     => 206158,
          :disk                    => 0,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 0
        },
        {
          :id                      => "m6i.16xlarge",
          :name                    => "m6i Sixteen Extra Large",
          :bits                    => 64,
          :cores                   => 64,
          :ram                     => 274878,
          :disk                    => 0,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 0
        },
        {
          :id                      => "m6i.24xlarge",
          :name                    => "m6i Twenty Four Extra Large",
          :bits                    => 64,
          :cores                   => 96,
          :ram                     => 412316,
          :disk                    => 0,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 0
        },
        {
          :id                      => "m6i.32xlarge",
          :name                    => "m6i Thirty Two Extra Large",
          :bits                    => 64,
          :cores                   => 128,
          :ram                     => 549756,
          :disk                    => 0,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 0
        },
        {
          :id                      => "m6i.metal",
          :name                    => "m6i metal",
          :bits                    => 64,
          :cores                   => 128,
          :ram                     => 549756,
          :disk                    => 0,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 0
        },
        {
          :id                      => "m6id.large",
          :name                    => "m6id Large",
          :bits                    => 64,
          :cores                   => 2,
          :ram                     => 8589,
          :disk                    => 118,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 1
        },
        {
          :id                      => "m6id.xlarge",
          :name                    => "m6id Extra Large",
          :bits                    => 64,
          :cores                   => 4,
          :ram                     => 17179,
          :disk                    => 237,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 1
        },
        {
          :id                      => "m6id.2xlarge",
          :name                    => "m6id Double Extra Large",
          :bits                    => 64,
          :cores                   => 8,
          :ram                     => 34359,
          :disk                    => 474,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 1
        },
        {
          :id                      => "m6id.4xlarge",
          :name                    => "m6id Quadruple Extra Large",
          :bits                    => 64,
          :cores                   => 16,
          :ram                     => 68719,
          :disk                    => 950,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 1
        },
        {
          :id                      => "m6id.8xlarge",
          :name                    => "m6id Octuple Extra Large",
          :bits                    => 64,
          :cores                   => 32,
          :ram                     => 137439,
          :disk                    => 1900,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 1
        },
        {
          :id                      => "m6id.12xlarge",
          :name                    => "m6id Twelve Extra Large",
          :bits                    => 64,
          :cores                   => 48,
          :ram                     => 206158,
          :disk                    => 1425,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 2
        },
        {
          :id                      => "m6id.16xlarge",
          :name                    => "m6id Sixteen Extra Large",
          :bits                    => 64,
          :cores                   => 64,
          :ram                     => 274878,
          :disk                    => 1900,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 2
        },
        {
          :id                      => "m6id.24xlarge",
          :name                    => "m6id Twenty Four Extra Large",
          :bits                    => 64,
          :cores                   => 96,
          :ram                     => 412316,
          :disk                    => 1425,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 4
        },
        {
          :id                      => "m6id.32xlarge",
          :name                    => "m6id Thirty Two Extra Large",
          :bits                    => 64,
          :cores                   => 128,
          :ram                     => 549756,
          :disk                    => 1900,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 4
        },
        {
          :id                      => "m6id.metal",
          :name                    => "m6id metal",
          :bits                    => 64,
          :cores                   => 128,
          :ram                     => 549756,
          :disk                    => 1900,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 4
        },
        {
          :id                      => "m6in.large",
          :name                    => "m6in Large",
          :bits                    => 64,
          :cores                   => 2,
          :ram                     => 8589,
          :disk                    => 0,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 0
        },
        {
          :id                      => "m6in.xlarge",
          :name                    => "m6in Extra Large",
          :bits                    => 64,
          :cores                   => 4,
          :ram                     => 17179,
          :disk                    => 0,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 0
        },
        {
          :id                      => "m6in.2xlarge",
          :name                    => "m6in Double Extra Large",
          :bits                    => 64,
          :cores                   => 8,
          :ram                     => 34359,
          :disk                    => 0,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 0
        },
        {
          :id                      => "m6in.4xlarge",
          :name                    => "m6in Quadruple Extra Large",
          :bits                    => 64,
          :cores                   => 16,
          :ram                     => 68719,
          :disk                    => 0,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 0
        },
        {
          :id                      => "m6in.8xlarge",
          :name                    => "m6in Octuple Extra Large",
          :bits                    => 64,
          :cores                   => 32,
          :ram                     => 137439,
          :disk                    => 0,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 0
        },
        {
          :id                      => "m6in.12xlarge",
          :name                    => "m6in Twelve Extra Large",
          :bits                    => 64,
          :cores                   => 48,
          :ram                     => 206158,
          :disk                    => 0,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 0
        },
        {
          :id                      => "m6in.16xlarge",
          :name                    => "m6in Sixteen Extra Large",
          :bits                    => 64,
          :cores                   => 64,
          :ram                     => 274878,
          :disk                    => 0,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 0
        },
        {
          :id                      => "m6in.24xlarge",
          :name                    => "m6in Twenty Four Extra Large",
          :bits                    => 64,
          :cores                   => 96,
          :ram                     => 412316,
          :disk                    => 0,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 0
        },
        {
          :id                      => "m6in.32xlarge",
          :name                    => "m6in Thirty Two Extra Large",
          :bits                    => 64,
          :cores                   => 128,
          :ram                     => 549756,
          :disk                    => 0,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 0
        },
        {
          :id                      => "m6in.metal",
          :name                    => "m6in metal",
          :bits                    => 64,
          :cores                   => 128,
          :ram                     => 549756,
          :disk                    => 0,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 0
        },
        {
          :id                      => "m6idn.large",
          :name                    => "m6idn Large",
          :bits                    => 64,
          :cores                   => 2,
          :ram                     => 8589,
          :disk                    => 118,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 1
        },
        {
          :id                      => "m6idn.xlarge",
          :name                    => "m6idn Extra Large",
          :bits                    => 64,
          :cores                   => 4,
          :ram                     => 17179,
          :disk                    => 237,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 1
        },
        {
          :id                      => "m6idn.2xlarge",
          :name                    => "m6idn Double Extra Large",
          :bits                    => 64,
          :cores                   => 8,
          :ram                     => 34359,
          :disk                    => 474,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 1
        },
        {
          :id                      => "m6idn.4xlarge",
          :name                    => "m6idn Quadruple Extra Large",
          :bits                    => 64,
          :cores                   => 16,
          :ram                     => 68719,
          :disk                    => 950,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 1
        },
        {
          :id                      => "m6idn.8xlarge",
          :name                    => "m6idn Octuple Extra Large",
          :bits                    => 64,
          :cores                   => 32,
          :ram                     => 137439,
          :disk                    => 1900,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 1
        },
        {
          :id                      => "m6idn.12xlarge",
          :name                    => "m6idn Twelve Extra Large",
          :bits                    => 64,
          :cores                   => 48,
          :ram                     => 206158,
          :disk                    => 1425,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 2
        },
        {
          :id                      => "m6idn.16xlarge",
          :name                    => "m6idn Sixteen Extra Large",
          :bits                    => 64,
          :cores                   => 64,
          :ram                     => 274878,
          :disk                    => 1900,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 2
        },
        {
          :id                      => "m6idn.24xlarge",
          :name                    => "m6idn Twenty Four Extra Large",
          :bits                    => 64,
          :cores                   => 96,
          :ram                     => 412316,
          :disk                    => 1425,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 4
        },
        {
          :id                      => "m6idn.32xlarge",
          :name                    => "m6idn Thirty Two Extra Large",
          :bits                    => 64,
          :cores                   => 128,
          :ram                     => 549756,
          :disk                    => 1900,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 4
        },
        {
          :id                      => "m6idn.metal",
          :name                    => "m6idn metal",
          :bits                    => 64,
          :cores                   => 128,
          :ram                     => 549756,
          :disk                    => 1900,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 4
        },
        {
          :id                      => "m5d.large",
          :name                    => "M5d Large",
          :bits                    => 64,
          :cores                   => 2,
          :ram                     => 8589,
          :disk                    => 75,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 1
        },
        {
          :id                      => "m5d.xlarge",
          :name                    => "M5d Extra Large",
          :bits                    => 64,
          :cores                   => 4,
          :ram                     => 17179,
          :disk                    => 150,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 1
        },
        {
          :id                      => "m5d.2xlarge",
          :name                    => "M5d Double Extra Large",
          :bits                    => 64,
          :cores                   => 8,
          :ram                     => 34359,
          :disk                    => 300,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 1
        },
        {
          :id                      => "m5d.4xlarge",
          :name                    => "M5d Quadruple Extra Large",
          :bits                    => 64,
          :cores                   => 16,
          :ram                     => 68719,
          :disk                    => 600,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 2
        },
        {
          :id                      => "m5d.8xlarge",
          :name                    => "M5d Octuple Extra Large",
          :bits                    => 64,
          :cores                   => 32,
          :ram                     => 137439,
          :disk                    => 1200,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 2
        },
        {
          :id                      => "m5d.12xlarge",
          :name                    => "M5d Twelve Extra Large",
          :bits                    => 64,
          :cores                   => 48,
          :ram                     => 206158,
          :disk                    => 1800,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 2
        },
        {
          :id                      => "m5d.16xlarge",
          :name                    => "M5d Sixteen Extra Large",
          :bits                    => 64,
          :cores                   => 64,
          :ram                     => 274878,
          :disk                    => 2400,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 4
        },
        {
          :id                      => "m5d.24xlarge",
          :name                    => "M5d Twenty Four Extra Large",
          :bits                    => 64,
          :cores                   => 96,
          :ram                     => 412316,
          :disk                    => 3600,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 4
        },
        {
          :id                      => "m5d.metal",
          :name                    => "M5d Metal",
          :bits                    => 64,
          :cores                   => 96,
          :ram                     => 412316,
          :disk                    => 3600,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 4
        },
        {
          :id                      => "m5a.large",
          :name                    => "M5 (AMD) Large",
          :bits                    => 64,
          :cores                   => 2,
          :ram                     => 8589,
          :disk                    => 0,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 0
        },
        {
          :id                      => "m5a.xlarge",
          :name                    => "M5 (AMD) Extra Large",
          :bits                    => 64,
          :cores                   => 4,
          :ram                     => 17179,
          :disk                    => 0,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 0
        },
        {
          :id                      => "m5a.2xlarge",
          :name                    => "M5 (AMD) Double Extra Large",
          :bits                    => 64,
          :cores                   => 8,
          :ram                     => 34359,
          :disk                    => 0,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 0
        },
        {
          :id                      => "m5a.4xlarge",
          :name                    => "M5 (AMD) Quadruple Extra Large",
          :bits                    => 64,
          :cores                   => 16,
          :ram                     => 68719,
          :disk                    => 0,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 0
        },
        {
          :id                      => "m5a.8xlarge",
          :name                    => "M5 (AMD) Eight Extra Large",
          :bits                    => 64,
          :cores                   => 32,
          :ram                     => 137438,
          :disk                    => 0,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 0
        },
        {
          :id                      => "m5a.12xlarge",
          :name                    => "M5 (AMD) Twelve Extra Large",
          :bits                    => 64,
          :cores                   => 48,
          :ram                     => 206158,
          :disk                    => 0,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 0
        },
        {
          :id                      => "m5a.16xlarge",
          :name                    => "M5 (AMD) Sixteen Extra Large",
          :bits                    => 64,
          :cores                   => 32,
          :ram                     => 274877,
          :disk                    => 0,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 0
        },
        {
          :id                      => "m5a.24xlarge",
          :name                    => "M5 (AMD) Twenty Four Extra Large",
          :bits                    => 64,
          :cores                   => 96,
          :ram                     => 412316,
          :disk                    => 0,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 0
        },
        {
          :id                      => "m5ad.large",
          :name                    => "M5ad (AMD) Large",
          :bits                    => 64,
          :cores                   => 2,
          :ram                     => 8589,
          :disk                    => 75,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 0
        },
        {
          :id                      => "m5ad.xlarge",
          :name                    => "M5ad (AMD) Extra Large",
          :bits                    => 64,
          :cores                   => 4,
          :ram                     => 17179,
          :disk                    => 150,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 0
        },
        {
          :id                      => "m5ad.2xlarge",
          :name                    => "M5ad (AMD) Double Extra Large",
          :bits                    => 64,
          :cores                   => 8,
          :ram                     => 34359,
          :disk                    => 300,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 0
        },
        {
          :id                      => "m5ad.4xlarge",
          :name                    => "M5ad (AMD) Quadruple Extra Large",
          :bits                    => 64,
          :cores                   => 16,
          :ram                     => 68719,
          :disk                    => 600,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 0
        },
        {
          :id                      => "m5ad.12xlarge",
          :name                    => "M5ad (AMD) Twelve Extra Large",
          :bits                    => 64,
          :cores                   => 48,
          :ram                     => 206158,
          :disk                    => 1800,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 0
        },
        {
          :id                      => "m5ad.24xlarge",
          :name                    => "M5ad (AMD) Twenty-four Extra Large",
          :bits                    => 64,
          :cores                   => 96,
          :ram                     => 412316,
          :disk                    => 3600,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 0
        },
        {
          :id                      => "m5n.large",
          :name                    => "M5n Large",
          :bits                    => 64,
          :cores                   => 2,
          :ram                     => 8590,
          :disk                    => 0,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 0
        },
        {
          :id                      => "m5n.xlarge",
          :name                    => "M5n Extra Large",
          :bits                    => 64,
          :cores                   => 4,
          :ram                     => 17180,
          :disk                    => 0,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 0
        },
        {
          :id                      => "m5n.2xlarge",
          :name                    => "M5n Double Extra Large",
          :bits                    => 64,
          :cores                   => 8,
          :ram                     => 34360,
          :disk                    => 0,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 0
        },
        {
          :id                      => "m5n.4xlarge",
          :name                    => "M5n Quadruple Extra Large",
          :bits                    => 64,
          :cores                   => 16,
          :ram                     => 68719,
          :disk                    => 0,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 0
        },
        {
          :id                      => "m5n.8xlarge",
          :name                    => "M5n Octuple Extra Large",
          :bits                    => 64,
          :cores                   => 32,
          :ram                     => 137439,
          :disk                    => 0,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 0
        },
        {
          :id                      => "m5n.12xlarge",
          :name                    => "M5n Twelve Extra Large",
          :bits                    => 64,
          :cores                   => 48,
          :ram                     => 206158,
          :disk                    => 0,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 0
        },
        {
          :id                      => "m5n.16xlarge",
          :name                    => "M5n Sixteen Extra Large",
          :bits                    => 64,
          :cores                   => 64,
          :ram                     => 274878,
          :disk                    => 0,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 0
        },
        {
          :id                      => "m5n.24xlarge",
          :name                    => "M5n Twenty-Four Extra Large",
          :bits                    => 64,
          :cores                   => 96,
          :ram                     => 412317,
          :disk                    => 0,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 0
        },
        {
          :id                      => "m5dn.large",
          :name                    => "M5dn Large",
          :bits                    => 64,
          :cores                   => 2,
          :ram                     => 8590,
          :disk                    => 75,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 1
        },
        {
          :id                      => "m5dn.xlarge",
          :name                    => "M5dn Extra Large",
          :bits                    => 64,
          :cores                   => 4,
          :ram                     => 17180,
          :disk                    => 150,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 1
        },
        {
          :id                      => "m5dn.2xlarge",
          :name                    => "M5dn Double Extra Large",
          :bits                    => 64,
          :cores                   => 8,
          :ram                     => 34360,
          :disk                    => 300,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 1
        },
        {
          :id                      => "m5dn.4xlarge",
          :name                    => "M5dn Quadruple Extra Large",
          :bits                    => 64,
          :cores                   => 16,
          :ram                     => 68719,
          :disk                    => 600,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 2
        },
        {
          :id                      => "m5dn.8xlarge",
          :name                    => "M5dn Octuple Extra Large",
          :bits                    => 64,
          :cores                   => 32,
          :ram                     => 137439,
          :disk                    => 1200,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 2
        },
        {
          :id                      => "m5dn.12xlarge",
          :name                    => "M5dn Twelve Extra Large",
          :bits                    => 64,
          :cores                   => 48,
          :ram                     => 206158,
          :disk                    => 1800,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 2
        },
        {
          :id                      => "m5dn.16xlarge",
          :name                    => "M5dn Sixteen Extra Large",
          :bits                    => 64,
          :cores                   => 64,
          :ram                     => 274878,
          :disk                    => 2400,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 4
        },
        {
          :id                      => "m5dn.24xlarge",
          :name                    => "M5dn Twenty-Four Extra Large",
          :bits                    => 64,
          :cores                   => 96,
          :ram                     => 412317,
          :disk                    => 3600,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 4
        },
        {
          :id                      => "p2.xlarge",
          :name                    => "General Purpose GPU Extra Large",
          :bits                    => 64,
          :cores                   => 4,
          :ram                     => 65498,
          :disk                    => 0,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 0
        },
        {
          :id                      => "p2.8xlarge",
          :name                    => "General Purpose GPU Eight Extra Large",
          :bits                    => 64,
          :cores                   => 32,
          :ram                     => 523986,
          :disk                    => 0,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 0
        },
        {
          :id                      => "p2.16xlarge",
          :name                    => "General Purpose GPU Sixteen Extra Large",
          :bits                    => 64,
          :cores                   => 64,
          :ram                     => 785979,
          :disk                    => 0,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 0
        },
        {
          :id                      => "p3.2xlarge",
          :name                    => "Tesla GPU Two Extra Large",
          :bits                    => 64,
          :cores                   => 8,
          :ram                     => 65498,
          :disk                    => 0,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 0
        },
        {
          :id                      => "p3.8xlarge",
          :name                    => "Tesla GPU Eight Extra Large",
          :bits                    => 64,
          :cores                   => 32,
          :ram                     => 261993,
          :disk                    => 0,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 0
        },
        {
          :id                      => "p3.16xlarge",
          :name                    => "Tesla GPU Sixteen Extra Large",
          :bits                    => 64,
          :cores                   => 64,
          :ram                     => 523986,
          :disk                    => 0,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 0
        },
        {
          :id                      => "p3dn.24xlarge",
          :name                    => "Tesla GPU Twenty-four Extra Large",
          :bits                    => 64,
          :cores                   => 96,
          :ram                     => 824634,
          :disk                    => 1800,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 2
        },
        {
          :id                      => 'inf1.xlarge',
          :name                    => 'Inf1 Extra Large',
          :bits                    => 64,
          :cores                   => 4,
          :disk                    => 0,
          :ram                     => 8590,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 0
        },
        {
          :id                      => 'inf1.2xlarge',
          :name                    => 'Inf1 Double xtra Large',
          :bits                    => 64,
          :cores                   => 8,
          :disk                    => 0,
          :ram                     => 17180,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 0
        },
        {
          :id                      => 'inf1.6xlarge',
          :name                    => 'Inf1 Sextuple Extra Large',
          :bits                    => 64,
          :cores                   => 24,
          :disk                    => 0,
          :ram                     => 51540,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 0
        },
        {
          :id                      => 'inf1.24xlarge',
          :name                    => 'Inf1 Twenty-four Extra Large',
          :bits                    => 64,
          :cores                   => 96,
          :disk                    => 0,
          :ram                     => 206158,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 0
        },
        {
          :id                      => 'g3s.xlarge',
          :name                    => 'G3s Extra Large',
          :bits                    => 64,
          :cores                   => 4,
          :disk                    => 0,
          :ram                     => 32749,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 0
        },
        {
          :id                      => 'g3.4xlarge',
          :name                    => 'G3 Quadruple Extra Large',
          :bits                    => 64,
          :cores                   => 16,
          :disk                    => 0,
          :ram                     => 130996,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 0
        },
        {
          :id                      => 'g3.8xlarge',
          :name                    => 'G3 Octuple Extra Large',
          :bits                    => 64,
          :cores                   => 32,
          :disk                    => 0,
          :ram                     => 261993,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 0
        },
        {
          :id                      => 'g3.16xlarge',
          :name                    => 'G3 Sixteen Extra Large',
          :bits                    => 64,
          :cores                   => 64,
          :disk                    => 0,
          :ram                     => 523986,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 0
        },
        {
          :id                      => 'g3dn.xlarge',
          :name                    => 'G3dn Extra Large',
          :bits                    => 64,
          :cores                   => 4,
          :disk                    => 125,
          :ram                     => 171780,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 1
        },
        {
          :id                      => 'g3dn.2xlarge',
          :name                    => 'G3dn Double Extra Large',
          :bits                    => 64,
          :cores                   => 8,
          :disk                    => 225,
          :ram                     => 34360,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 1
        },
        {
          :id                      => 'g3dn.4xlarge',
          :name                    => 'G3dn Quadruple Extra Large',
          :bits                    => 64,
          :cores                   => 16,
          :disk                    => 225,
          :ram                     => 68719,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 1
        },
        {
          :id                      => 'g3dn.8xlarge',
          :name                    => 'G3dn Octuple Extra Large',
          :bits                    => 64,
          :cores                   => 32,
          :disk                    => 900,
          :ram                     => 137439,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 1
        },
        {
          :id                      => 'g3dn.16xlarge',
          :name                    => 'G3dn Sixteen Extra Large',
          :bits                    => 64,
          :cores                   => 64,
          :disk                    => 900,
          :ram                     => 274878,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 1
        },
        {
          :id                      => 'g3dn.12xlarge',
          :name                    => 'G3dn Twelve Extra Large (4GPU)',
          :bits                    => 64,
          :cores                   => 48,
          :disk                    => 900,
          :ram                     => 206158,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 1
        },
        {
          :id                      => 'g3dn.metal',
          :name                    => 'G3dn Metal (8GPU)',
          :bits                    => 64,
          :cores                   => 96,
          :disk                    => 1800,
          :ram                     => 412317,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 2
        },
        {
          :id                      => 'f1.2xlarge',
          :name                    => 'F1 Double Extra Large',
          :bits                    => 64,
          :cores                   => 8,
          :disk                    => 470,
          :ram                     => 130997,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 1
        },
        {
          :id                      => 'f1.4xlarge',
          :name                    => 'F1 Quadruple Extra Large',
          :bits                    => 64,
          :cores                   => 16,
          :disk                    => 940,
          :ram                     => 261993,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 1
        },
        {
          :id                      => 'f1.16xlarge',
          :name                    => 'F1 Sixteen Extra Large',
          :bits                    => 64,
          :cores                   => 64,
          :disk                    => 3760,
          :ram                     => 1047972,
          :ebs_optimized_available => true,
          :instance_store_volumes  => 4
        }
      ]

      class Flavors < Fog::Collection
        model Fog::AWS::Compute::Flavor

        # Returns an array of all flavors that have been created
        #
        # AWS.flavors.all
        #
        # ==== Returns
        #
        # Returns an array of all available instances and their general information
        #
        #>> AWS.flavors.all
        #  <Fog::AWS::Compute::Flavors
        #    [
        #      <Fog::AWS::Compute::Flavor
        #        id="t1.micro",
        #        bits=0,
        #        cores=2,
        #        disk=0,
        #        name="Micro Instance",
        #        ram=613,
        #        ebs_optimized_available=false,
        #        instance_store_volumes=0
        #      >,
        #      <Fog::AWS::Compute::Flavor
        #        id="m1.small",
        #        bits=32,
        #        cores=1,
        #        disk=160,
        #        name="Small Instance",
        #        ram=1740.8,
        #        ebs_optimized_available=false,
        #        instance_store_volumes=1
        #      >,
        #      <Fog::AWS::Compute::Flavor
        #        id="m1.medium",
        #        bits=32,
        #        cores=2,
        #        disk=400,
        #        name="Medium Instance",
        #        ram=3750,
        #        ebs_optimized_available=false,
        #        instance_store_volumes=1
        #      >,
        #      <Fog::AWS::Compute::Flavor
        #        id="m1.large",
        #        bits=64,
        #        cores=4,
        #        disk=850,
        #        name="Large Instance",
        #        ram=7680,
        #        ebs_optimized_available=true
        #        instance_store_volumes=2
        #      >,
        #      <Fog::AWS::Compute::Flavor
        #        id="m1.xlarge",
        #        bits=64,
        #        cores=8,
        #        disk=1690,
        #        name="Extra Large Instance",
        #        ram=15360,
        #        ebs_optimized_available=true,
        #        instance_store_volumes=4
        #
        #      >,
        #      <Fog::AWS::Compute::Flavor
        #        id="c1.medium",
        #        bits=32,
        #        cores=5,
        #        disk=350,
        #        name="High-CPU Medium",
        #        ram=1740.8,
        #        ebs_optimized_available=false,
        #        instance_store_volumes=1
        #      >,
        #      <Fog::AWS::Compute::Flavor
        #        id="c1.xlarge",
        #        bits=64,
        #        cores=20,
        #        disk=1690,
        #        name="High-CPU Extra Large",
        #        ram=7168,
        #        ebs_optimized_available=true,
        #        instance_store_volumes=4
        #      >,
        #      <Fog::AWS::Compute::Flavor
        #        id="m2.xlarge",
        #        bits=64,
        #        cores=6.5,
        #        disk=420,
        #        name="High-Memory Extra Large",
        #        ram=17510.4,
        #        ebs_optimized_available=false,
        #        instance_store_volumes=1
        #      >,
        #      <Fog::AWS::Compute::Flavor
        #        id="m2.2xlarge",
        #        bits=64,
        #        cores=13,
        #        disk=850,
        #        name="High Memory Double Extra Large",
        #        ram=35020.8,
        #        ebs_optimized_available=true,
        #        instance_store_volumes=1
        #      >,
        #      <Fog::AWS::Compute::Flavor
        #        id="m2.4xlarge",
        #        bits=64,
        #        cores=26,
        #        disk=1690,
        #        name="High Memory Quadruple Extra Large",
        #        ram=70041.6,
        #        ebs_optimized_available=true,
        #        instance_store_volumes=2
        #      >,
        #      <Fog::AWS::Compute::Flavor
        #        id="cc1.4xlarge",
        #        bits=64,
        #        cores=33.5,
        #        disk=1690,
        #        name="Cluster Compute Quadruple Extra Large",
        #        ram=23552,
        #        ebs_optimized_available=false,
        #        instance_store_volumes=0
        #      >,
        #      <Fog::AWS::Compute::Flavor
        #        id="m3.xlarge",
        #        bits=64,
        #        cores=13,
        #        disk=0,
        #        name="M3 Extra Large",
        #        ram=15360,
        #        ebs_optimized_available=true,
        #        instance_store_volumes=2
        #      >,
        #      <Fog::AWS::Compute::Flavor
        #        id="m3.2xlarge",
        #        bits=64,
        #        cores=26,
        #        disk=0,
        #        name="M3 Double Extra Large",
        #        ram=30720,
        #        ebs_optimized_available=true,
        #        instance_store_volumes=2
        #      >,
        #      <Fog::AWS::Compute::Flavor
        #        id="cc2.8xlarge",
        #        bits=64,
        #        cores=88,
        #        disk=3370,
        #        name="Cluster Compute Eight Extra Large",
        #        ram=61952,
        #        ebs_optimized_available=false,
        #        instance_store_volumes=4
        #      >,
        #      <Fog::AWS::Compute::Flavor
        #        id="cg1.4xlarge",
        #        bits=64,
        #        cores=33.5,
        #        disk=1690,
        #        name="Cluster GPU Quadruple Extra Large",
        #        ram=22528,
        #        ebs_optimized_available=false,
        #        instance_store_volumes=2
        #      >
        #    ]
        #  >
        #

        def all
          load(Fog::AWS::Compute::FLAVORS)
          self
        end

        # Used to retrieve a flavor
        # flavor_id is required to get the associated flavor information.
        # flavors available currently:
        #
        # t1.micro
        # m1.small, m1.medium, m1.large, m1.xlarge
        # c1.medium, c1.xlarge
        # c3.large, c3.xlarge, c3.2xlarge, c3.4xlarge, c3.8xlarge
        # g2.2xlarge
        # hs1.8xlarge
        # m2.xlarge, m2.2xlarge, m2.4xlarge
        # m3.xlarge, m3.2xlarge
        # cr1.8xlarge
        # cc1.4xlarge
        # cc2.8xlarge
        # cg1.4xlarge
        # i2.xlarge, i2.2xlarge, i2.4xlarge, i2.8xlarge
        #
        # You can run the following command to get the details:
        # AWS.flavors.get("t1.micro")
        #
        # ==== Returns
        #
        #>> AWS.flavors.get("t1.micro")
        # <Fog::AWS::Compute::Flavor
        #  id="t1.micro",
        #  bits=0,
        #  cores=2,
        #  disk=0,
        #  name="Micro Instance",
        #  ram=613
        #  ebs_optimized_available=false
        #  instance_store_volumes=0
        #>
        #

        def get(flavor_id)
          self.class.new(:service => service).all.find {|flavor| flavor.id == flavor_id}
        end
      end
    end
  end
end
