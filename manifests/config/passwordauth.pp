#
# == Define: openvpn::config::passwordauth
#
# Configure auth-user-pass file
#
# == Parameters
#
# [*title*]
#   While not strictly a parameter, $title must match that of the OpenVPN 
#   connection.
# [*username*]
#   This client's username. Omit to skip creation of a credentials file used for 
#   automatic connections. No default value.
# [*password*]
#   This client's password.
# [*role*]
#   Connection type. Either 'client' or 'server'. Affects location of the
#   password file on some platforms.
#
define openvpn::config::passwordauth
(
    String                  $username,
    String                  $password,
    Enum['client','server'] $role,
)
{
    include ::openvpn::params

    if $::openvpn::params::config_split {
        $basedir = $role ? {
            'client' => $::openvpn::params::client_config_dir,
            'server' => $::openvpn::params::server_config_dir,
        }
    } else {
        $basedir = $::openvpn::params::config_dir
    }

    # Special case path for Windows
    $passfile = $::kernel ? {
        'windows' => "${basedir}\\${title}.pass",
        default   => "${basedir}/${title}.pass"
    }

    file { "openvpn-${title}.pass":
        ensure  => present,
        name    => $passfile,
        content => template('openvpn/client-passwordauth.pass.erb'),
        owner   => $::os::params::adminuser,
        group   => $::os::params::admingroup,
        mode    => '0600',
        seluser => $::openvpn::params::seluser,
        selrole => $::openvpn::params::selrole,
        seltype => $::openvpn::params::seltype,
        require => Class['openvpn::install'],
        notify  => Class['openvpn::service'],
    }
}
