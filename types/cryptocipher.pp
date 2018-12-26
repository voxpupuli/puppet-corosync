# @summary Defines the allowed cipher types for secure corosync communication
type Corosync::CryptoCipher = Enum[
  'aes256',
  'aes192',
  'aes128',
  '3des',
]
