# @summary Custom type for syslog priority enum
#
type Corosync::Syslogpriority = Enum[
  'debug',
  'info',
  'notice',
  'warning',
  'err',
  'alert',
  'emerg',
  'crit'
]
