#
# == Definition: postfix::config
#
# Uses Augeas to add/alter/remove options in postfix main
# configuation file (/etc/postfix/main.cf).
#
# TODO: make this a type with an Augeas and a postconf providers.
#
# === Parameters
#
# [*name*]   - name of the parameter.
# [*ensure*] - present/absent/blank. defaults to present.
# [*value*]  - value of the parameter.
#
# === Requires
#
# - Class["postfix"]
#
# === Examples
#
#   postfix::config { 'smtp_use_tls':
#     ensure => 'present',
#     value  => 'yes',
#   }
#
#   postfix::config { 'relayhost':
#     ensure => 'blank',
#   }
#
# === Notes
# Worth mentioning that if an $ensure is 'present', however $value was not provided -
# it is implied that a user did not make a mistake, rather made a stub reservation
# for this $title. For this case, making a defined type to return without failing
# Use case: multi-server type deployments, which use postfix puppet module. They
# normally yes a wrapper around it (a.k.a profile). This is beneficial to have this
# wrappe configured with a union of config options used for all server types. Then
# use hiera to configure necessary options for each server type individually. Currently
# such an approach fails, due to assert_type check. Without this functionality it would be
# required to maintain X number of profiles - 1 per server type.
# 
define postfix::config (
  Optional[String]                   $value  = undef,
  Enum['present', 'absent', 'blank'] $ensure = 'present',
) {

  if ($ensure == 'present') {
    if (!defined('$value')) {
      return "${title} value is undefined"
    }
    assert_type(Pattern[/^.+$/], $value) |$e, $a| {
      fail '$value can not be empty if ensure = present'
    }
  }

  if (!defined(Class['postfix'])) {
    fail 'You must define class postfix before using postfix::config!'
  }

  case $ensure {
    'present': {
      $changes = "set ${name} '${value}'"
    }
    'absent': {
      $changes = "rm ${name}"
    }
    'blank': {
      $changes = "clear ${name}"
    }
    default: {
      fail "Unknown value for ensure '${ensure}'"
    }
  }

  augeas { "manage postfix '${title}'":
    incl    => '/etc/postfix/main.cf',
    lens    => 'Postfix_Main.lns',
    changes => $changes,
    require => File['/etc/postfix/main.cf'],
  }

  Postfix::Config[$title] ~> Class['postfix::service']
}
