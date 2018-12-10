#
# == Define: openvpn::server::dynamic
#
# Setup an OpenVPN server based on a configuration file template. This define
# can reuse Puppet certificates and keys, or use ones created with another CA 
# such as Easy-RSA 3.
#
# == Parameters
#
# [*manage_packetfilter*]
#   Manage packet filtering rules. Valid values are true (default) and false.
# [*manage_monit*]
#   Manage monit rules. Valid values are true (default) and false.
# [*vpn_network*]
#   The VPN network. For example '10.8.0.0'.
# [*vpn_netmask*]
#   The VPN netmask. Defaults to '255.255.255.0'.
# [*tunif*]
#   The name of the tunnel interface to use. Setting this manually is necessary
#   to allow setup of proper iptables/ip6tables rules. The default value is
#   'tun5'.
# [*max_clients*]
#   Maximum allowed number of clients. Defaults 50.
# [*local_port*]
#   The local port on which OpenVPN listens for requests. Defaults to 1194.
# [*use_puppetcerts*]
#   Reuse Puppet's certificates for OpenVPN. Valid values are true (default) and 
#   false.
# [*route*]
#   An array of routes to setup on the server. Defaults to undef.
# [*push*]
#   An array of configuration settings to push from the server to the clients.
#   Defaults to undef.
# [*nat*]
#   NAT configuration as a hash:
#      source: the source network (VPN address pool), for example 10.44.55.0/24
#      destination: the destination network, for example 192.168.1.0/24
# [*files_baseurl*]
#   Base URL for static OpenVPN config files and keys. Defaults to
#   'puppet:///files'.
#
define openvpn::server::dynamic
(
    String           $vpn_network,
    Boolean          $manage_packetfilter = true,
    Boolean          $manage_monit = true,
    String           $vpn_netmask = '255.255.255.0',
    String           $tunif = 'tun5',
    Integer          $max_clients = 50,
    Integer          $local_port = 1194,
    Boolean          $use_puppetcerts = true,
    Optional[String] $files_baseurl = undef,
    Array[String]    $routes = [],
    Array[String]    $push = [],
    Optional[Hash]   $nat = undef
)
{
    include ::openvpn::params

    openvpn::server::generic { $title:
        manage_packetfilter => $manage_packetfilter,
        manage_monit        => $manage_monit,
        dynamic             => true,
        files_baseurl       => $files_baseurl,
        vpn_network         => $vpn_network,
        vpn_netmask         => $vpn_netmask,
        tunif               => $tunif,
        max_clients         => $max_clients,
        local_port          => $local_port,
        routes              => $routes,
        push                => $push,
        nat                 => $nat,
    }

    if $use_puppetcerts {
        openvpn::config::puppetcerts { $title: }
        openvpn::config::certs { $title:
            manage_dh           => true,
            manage_certs        => false,
            manage_client_certs => false,
            role                => 'server',
        }
    } else {
        openvpn::config::certs { $title:
            manage_dh           => true,
            manage_certs        => true,
            manage_client_certs => false,
            role                => 'server',
        }
    }
}
