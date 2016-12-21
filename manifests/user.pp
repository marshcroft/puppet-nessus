define nessus::user (
  $ensure          = 'present',
  $password_hash   = undef,
  $user_base       = '/opt/nessus/var/nessus/users',
  $admin           = false,
) {

  validate_re($ensure, ['^present', '^absent'], "nessus::user \$ensure must be present or absent, not ${ensure}")
  validate_bool($admin)
  validate_string($password_hash)
  validate_string($user_base)


  File {
    owner   => 'root',
    group   => 'root',
    mode    => '0600',
    require => Package['nessus'],
  }

  # Make sure that there is a toplevel user dir.
  if ! defined(File[$user_base]) {
    file { $user_base:
      ensure  => directory,
    }
  }

  if $ensure == 'present' {
    # create our directory structure for a user
    file { [ "${user_base}/${title}", "${user_base}/${title}/auth", "${user_base}/${title}/reports" ]:
      ensure => directory,
    }

    # Set the password as a hash. This will add your hashed password to a hash file which is needed by 6.9
    file { "${user_base}/${title}/auth/hash":
      ensure  => file,
      content => "${password_hash}\n",
      notify  => Service['nessus'],
    }

    # if we are an admin, just touch the admin file
    file { "${user_base}/${title}/auth/admin":
      ensure => $admin ? {
        true    => file,
        default => absent,
      },
      notify => Service['nessus'],
    }

    file { "${user_base}/${title}/auth/rules":
      ensure => file,
    }

  } elsif $ensure == 'absent' {
    file { "${user_base}/${title}":
      ensure  => absent,
      backup  => false,
      recurse => true,
      notify  => Service['nessus'],
    }
  }
}
