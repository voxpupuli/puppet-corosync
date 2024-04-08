# @summary Custom type for string <-> array of string variants
#
type Corosync::IpStringIp = Variant[
  Stdlib::IP::Address,
  Array[
    Stdlib::IP::Address
  ]
]
