#
# == Define: openvpn::client::dynamic
#
# Setup an OpenVPN client based on a configuration file template.
#
# == Parameters
#
# [*manage_packetfilter*]
#   Manage packet filtering rules. Valid values are true (default) and false.
# [*manage_monit*]
#   Manage monit rules. Valid values are true (default) and false.
# [*remote_ip*]
#   Remote VPN endpoint's IP address.
# [*remote_port*]
#   Remote VPN endpoint's port.
# [*float*]
#   Allow remote peer to change its IP. Useful when the inbound packets do not
#   always arrive from the --remote address. Valid values are true and false
#   (default).
# [*tunif*]
#   The name of the tunnel interface to use. The default value is 'tun5'.
# [*use_puppetcerts*]
#   Reuse Puppet's certificates for OpenVPN. Valid values are true (default) and 
#   false.
# [*enable_service*]
#   Whether to enable this connection at boot time, and to keep it running. 
#   Valid values are true (default) and false.
# [*username*]
#   Authentication username. Defining this implies that client certificate and 
#   private key are not needed nor installed. Defaults to undef.
# [*password*]
#   Authentication password. Defaults to undef, but must be defined if $username 
#   is set.
# [*up_script*]
#   A script to run after successful TUN/TAP device open. Typically this is used 
#   to setup /etc/resolv.conf. The default value is to use the operating 
#   system's default up script. For example, on Debian, this is 
#   "/etc/openvpn/update-resolv-conf". Set to undef to not run the script even 
#   if one is provided by the operating system.
# [*down_script*]
#   Same as $up_script, but run after TUN/TAP device close instead.
# [*files_baseurl*]
#   Base URL for static OpenVPN config files and keys. Defaults to
#   'puppet:///files'.
#
define openvpn::client::dynamic
(
    String           $remote_ip,
    Boolean          $manage_packetfilter = true,
    Boolean          $manage_monit = true,
    Integer          $remote_port = 1194,
    Boolean          $float = false,
    String           $tunif = 'tun5',
    Boolean          $use_puppetcerts = true,
    Boolean          $enable_service = true,
    Optional[String] $files_baseurl = undef,
    Optional[String] $username = undef,
    Optional[String] $password = undef,
    Optional[String] $up_script = $::openvpn::params::up_script,
    Optional[String] $down_script = $::openvpn::params::down_script
)
{
    include ::openvpn::params

    openvpn::client::generic { $title:
        manage_packetfilter => true,
        manage_monit        => true,
        dynamic             => true,
        files_baseurl       => $files_baseurl,
        remote_ip           => $remote_ip,
        remote_port         => $remote_port,
        float               => $float,
        enable_service      => $enable_service,
        tunif               => $tunif,
        username            => $username,
        password            => $password,
        up_script           => $up_script,
        down_script         => $down_script,
    }

    if $use_puppetcerts {
        openvpn::config::puppetcerts { $title: }
        # This class is only used for installing ta.key
        openvpn::config::certs { $title:
            manage_dh           => false,
            manage_certs        => false,
            manage_client_certs => false,
            role                => 'client',
        }
    } else {
        # Manage credentials file if we're using password authentication
        if $username {
            openvpn::config::passwordauth { $title:
                username => $username,
                password => $password,
                role     => 'client',
            }
            $manage_client_certs = false

        # We're not using password authentication, so we need client
        # certificates
        } else {
            $manage_client_certs = true
        }

        openvpn::config::certs { $title:
            manage_dh           => false,
            manage_certs        => true,
            manage_client_certs => $manage_client_certs,
            files_baseurl       => $files_baseurl,
            role                => 'client',
        }
    }
}
