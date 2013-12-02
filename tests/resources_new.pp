cs_primitive { 'foobar':
  ensure => present,
  primitive_class => 'ocf',
  provided_by     => 'pacemaker',
  primitive_type  => 'Dummy',
} ->
cs_clone { 'foobarclone':
  ensure => present,
  primitive => 'foobar',
  metadata => { 'globally-unique' => 'false', 'clone-max' => '2', 'target-role' => 'Started' },
}
cs_primitive { 'fugazi':
  ensure => present,
  primitive_class => 'ocf',
  provided_by     => 'pacemaker',
  primitive_type  => 'Dummy',
} ->
cs_location { 'fugazi_on_node_with_foobar':
  ensure => present,
  rsc => 'foobar',
  rules => [ { 'score' => '-INFINITY', 'operation' => 'or', 'expressions' => ['not_defined foobar', 'foobar lte 0'], }, ],
  require => Cs_primitive['foobarclone'],
}
