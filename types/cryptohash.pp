# @summary Custom type for possible crypto hashes
#
type Corosync::CryptoHash = Enum[
  'md5',
  'sha1',
  'sha256',
  'sha384',
  'sha512',
]
