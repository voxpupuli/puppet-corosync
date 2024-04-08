# @summary Custom type for infinitely nestable arrays
#
type Corosync::ArrayRing = Variant[
  Array[Stdlib::IP::Address],
  Array[
    Array[Stdlib::IP::Address]
  ]
]
