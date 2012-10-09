class corosync::reprobe {
  exec { 'crm resource reprobe':
    path        => ['/bin','/usr/bin','/sbin','/usr/sbin'],
    refreshonly => true,
  }
  Cs_primitive <| |> {
    notify => Exec['crm resource reprobe'],
  }
  Cs_colocation <| |> {
    notify => Exec['crm resource reprobe'],
  }
  Cs_order <| |> {
    notify => Exec['crm resource reprobe'],
  }
  Cs_group <| |> {
    notify => Exec['crm resource reprobe'],
  }
  Cs_commit <| |> {
    notify => Exec['crm resource reprobe'],
  }
}
