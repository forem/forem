module Zip
  RUNNING_ON_WINDOWS = RbConfig::CONFIG['host_os'] =~ /mswin|mingw|cygwin/i

  CENTRAL_DIRECTORY_ENTRY_SIGNATURE = 0x02014b50
  CDIR_ENTRY_STATIC_HEADER_LENGTH   = 46

  LOCAL_ENTRY_SIGNATURE                  = 0x04034b50
  LOCAL_ENTRY_STATIC_HEADER_LENGTH       = 30
  LOCAL_ENTRY_TRAILING_DESCRIPTOR_LENGTH = 4 + 4 + 4
  VERSION_MADE_BY                        = 52 # this library's version
  VERSION_NEEDED_TO_EXTRACT              = 20
  VERSION_NEEDED_TO_EXTRACT_ZIP64        = 45

  FILE_TYPE_FILE    = 0o10
  FILE_TYPE_DIR     = 0o04
  FILE_TYPE_SYMLINK = 0o12

  FSTYPE_FAT      = 0
  FSTYPE_AMIGA    = 1
  FSTYPE_VMS      = 2
  FSTYPE_UNIX     = 3
  FSTYPE_VM_CMS   = 4
  FSTYPE_ATARI    = 5
  FSTYPE_HPFS     = 6
  FSTYPE_MAC      = 7
  FSTYPE_Z_SYSTEM = 8
  FSTYPE_CPM      = 9
  FSTYPE_TOPS20   = 10
  FSTYPE_NTFS     = 11
  FSTYPE_QDOS     = 12
  FSTYPE_ACORN    = 13
  FSTYPE_VFAT     = 14
  FSTYPE_MVS      = 15
  FSTYPE_BEOS     = 16
  FSTYPE_TANDEM   = 17
  FSTYPE_THEOS    = 18
  FSTYPE_MAC_OSX  = 19
  FSTYPE_ATHEOS   = 30

  FSTYPES = {
    FSTYPE_FAT      => 'FAT'.freeze,
    FSTYPE_AMIGA    => 'Amiga'.freeze,
    FSTYPE_VMS      => 'VMS (Vax or Alpha AXP)'.freeze,
    FSTYPE_UNIX     => 'Unix'.freeze,
    FSTYPE_VM_CMS   => 'VM/CMS'.freeze,
    FSTYPE_ATARI    => 'Atari ST'.freeze,
    FSTYPE_HPFS     => 'OS/2 or NT HPFS'.freeze,
    FSTYPE_MAC      => 'Macintosh'.freeze,
    FSTYPE_Z_SYSTEM => 'Z-System'.freeze,
    FSTYPE_CPM      => 'CP/M'.freeze,
    FSTYPE_TOPS20   => 'TOPS-20'.freeze,
    FSTYPE_NTFS     => 'NTFS'.freeze,
    FSTYPE_QDOS     => 'SMS/QDOS'.freeze,
    FSTYPE_ACORN    => 'Acorn RISC OS'.freeze,
    FSTYPE_VFAT     => 'Win32 VFAT'.freeze,
    FSTYPE_MVS      => 'MVS'.freeze,
    FSTYPE_BEOS     => 'BeOS'.freeze,
    FSTYPE_TANDEM   => 'Tandem NSK'.freeze,
    FSTYPE_THEOS    => 'Theos'.freeze,
    FSTYPE_MAC_OSX  => 'Mac OS/X (Darwin)'.freeze,
    FSTYPE_ATHEOS   => 'AtheOS'.freeze
  }.freeze

  COMPRESSION_METHOD_STORE = 0
  COMPRESSION_METHOD_SHRINK = 1
  COMPRESSION_METHOD_REDUCE_1 = 2
  COMPRESSION_METHOD_REDUCE_2 = 3
  COMPRESSION_METHOD_REDUCE_3 = 4
  COMPRESSION_METHOD_REDUCE_4 = 5
  COMPRESSION_METHOD_IMPLODE = 6
  # RESERVED = 7
  COMPRESSION_METHOD_DEFLATE = 8
  COMPRESSION_METHOD_DEFLATE_64 = 9
  COMPRESSION_METHOD_PKWARE_DCLI = 10
  # RESERVED = 11
  COMPRESSION_METHOD_BZIP2 = 12
  # RESERVED = 13
  COMPRESSION_METHOD_LZMA = 14
  # RESERVED = 15
  COMPRESSION_METHOD_IBM_CMPSC = 16
  # RESERVED = 17
  COMPRESSION_METHOD_IBM_TERSE = 18
  COMPRESSION_METHOD_IBM_LZ77 = 19
  COMPRESSION_METHOD_JPEG = 96
  COMPRESSION_METHOD_WAVPACK = 97
  COMPRESSION_METHOD_PPMD = 98
  COMPRESSION_METHOD_AES = 99

  COMPRESSION_METHODS = {
    COMPRESSION_METHOD_STORE       => 'Store (no compression)',
    COMPRESSION_METHOD_SHRINK      => 'Shrink',
    COMPRESSION_METHOD_REDUCE_1    => 'Reduce with compression factor 1',
    COMPRESSION_METHOD_REDUCE_2    => 'Reduce with compression factor 2',
    COMPRESSION_METHOD_REDUCE_3    => 'Reduce with compression factor 3',
    COMPRESSION_METHOD_REDUCE_4    => 'Reduce with compression factor 4',
    COMPRESSION_METHOD_IMPLODE     => 'Implode',
    # RESERVED = 7
    COMPRESSION_METHOD_DEFLATE     => 'Deflate',
    COMPRESSION_METHOD_DEFLATE_64  => 'Deflate64(tm)',
    COMPRESSION_METHOD_PKWARE_DCLI => 'PKWARE Data Compression Library Imploding (old IBM TERSE)',
    # RESERVED = 11
    COMPRESSION_METHOD_BZIP2       => 'BZIP2',
    # RESERVED = 13
    COMPRESSION_METHOD_LZMA        => 'LZMA',
    # RESERVED = 15
    COMPRESSION_METHOD_IBM_CMPSC   => 'IBM z/OS CMPSC Compression',
    # RESERVED = 17
    COMPRESSION_METHOD_IBM_TERSE   => 'IBM TERSE (new)',
    COMPRESSION_METHOD_IBM_LZ77    => 'IBM LZ77 z Architecture (PFS)',
    COMPRESSION_METHOD_JPEG        => 'JPEG variant',
    COMPRESSION_METHOD_WAVPACK     => 'WavPack compressed data',
    COMPRESSION_METHOD_PPMD        => 'PPMd version I, Rev 1',
    COMPRESSION_METHOD_AES         => 'AES encryption'
  }.freeze
end
