#
# == Define: openvpn::client::passwordauth
#
# Setup a new OpenVPN client instance that connects to a server using a 
# password-based authentication backend (e.g. PAM or LDAP).
#
# This define expects to find a CA cert (ca.crt) and a shared key (ta.key) under 
# Puppet fileserver's root directory named like this:
#
#   openvpn-${title}-ca.crt
#   openvpn-${title}-ta.key
#
# == Parameters
#
# [*title*]
#   While not strictly a parameter, $title is used as an identifier for the VPN 
#   connection in filenames and such.
# [*autostart*]
#   If set to 'yes', enable the VPN connection on startup. Valid values 'yes' 
#   and 'no'. Defaults to 'yes'. For implementation details see the
#   openvpn::client::inline class.
# [*remote_host*]
#   Remote OpenVPN server IP address or hostname.
# [*remote_port*]
#   Remote OpenVPN server port
# [*tunif*]
#   The name of the tunnel interface to use. Setting this manually is necessary 
#   to allow setup of proper iptables/ip6tables rules. The default value is 
#   'tun10'.
# [*username*]
#   This client's username. Omit to skip creation of a credentials file used for 
#   automatic connections. No default value.
# [*password*]
#   This client's password.
#
define openvpn::client::passwordauth
(
    $autostart='yes',
    $remote_host,
    $remote_port,
    $tunif='tun10',
    $username='',
    $password=''
)
{

    include openvpn::params

    openvpn::config::client::noninline { "${title}": }

    openvpn::config::client::passwordauth { "${title}":
        autostart => $autostart,
        remote_host => $remote_host,
        remote_port => $remote_port,
        tunif => $tunif,
        username => $username,
        password => $password,
    }

    if tagged('monit') {
        openvpn::monit { "${title}": }
    }

    if tagged('packetfilter') {
        openvpn::packetfilter::common { "openvpn-${title}":
            tunif => "${tunif}",
        }
    }
}
