#
# == Define: openvpn::client::inline
#
# Setup a new OpenVPN client instance that uses a pre-made configuration with 
# the certificates inlined. This kind of configuration files are typically used 
# with Access Server, but can be generated using other tools, too.
#
# This module expects to find the inline configuration files in Puppet 
# fileserver's root directory, named using this naming convention:
#
#   openvpn-${title}-${fqdn}.conf
#
# == Parameters
#
# [*title*]
#   While not strictly a parameter, $title is used as an identifier for the VPN 
#   connection in filenames and such.
# [*manage_packetfilter*]
#   Manage packet filtering rules. Valid values are true (default) and false.
# [*manage_monit*]
#   Manage monit rules. Valid values are true (default) and false.
# [*enable_service*]
#   If set to true, enable the VPN connection on startup. Valid values are true 
#   and false. Defaults to true. Note that on non-systemd distros this feature 
#   is implemented by appending a ".disabled" to the config file suffix, because 
#   startup scripts in some operating systems (e.g. CentOS 6) blindly launch all 
#   files with .conf suffix in /etc/openvpn, while others have fine-grained 
#   controls over which VPN connections to start. However, even on those 
#   platforms co-existing with manually configured VPN connections would be 
#   fairly painful without this hack. This parameter also enables and disables 
#   monit monitoring as necessary.
# [*tunif*]
#   The name of the tunnel interface to use. Setting this manually is necessary
#   to allow setup of proper iptables/ip6tables rules. The default value is
#   'tun10'.
# [*clientname*]
#   Use this parameter to override $fqdn when downloading the configuration 
#   files. Very useful if you want to reuse the same client configuration on 
#   several different nodes. For example, if you created a file called 
#   "openvpn-myserver-allclients.conf", then you'd use "allclients" as the 
#   $clientname. No default value.
# [*files_baseurl*]
#   Base URL for static OpenVPN config files and keys. Defaults to
#   'puppet:///files'.
#
define openvpn::client::inline
(
    Boolean          $manage_packetfilter = true,
    Boolean          $manage_monit = true,
    Boolean          $enable_service = true,
    String           $tunif = 'tun10',
    Optional[String] $files_baseurl = undef,
    Optional[String] $clientname = undef
)
{

    include ::openvpn::params

    openvpn::client::generic { $title:
        manage_packetfilter => true,
        manage_monit        => true,
        dynamic             => false,
        files_baseurl       => $files_baseurl,
        enable_service      => $enable_service,
        tunif               => $tunif,
        clientname          => $clientname,
    }
}
