#
# == Class: openvpn::service 
#
# Ensure that the OpenVPN system service is enabled, if requested, expect on 
# systemd distros.
#
class openvpn::service
(
    Boolean                   $enable,
    Optional[Enum['running']] $ensure = undef

) inherits openvpn::params {

    # Distros which have systemd treat each VPN connection as a separate 
    # service, so the "main" OpenVPN service should be disabled. This prevents
    # startup script from starting all OpenVPN connections on boot, as happens
    # by default on Debian 8.x unless /etc/default/openvpn is modified.
    #
    if $::systemd {
        $service_enable = false
        $service_ensure = undef
    } else {
        $service_enable = $enable
        $service_ensure = $ensure
    }

    service { 'openvpn':
        ensure  => $service_ensure,
        name    => $::openvpn::params::service_name,
        enable  => $service_enable,
        require => Class['openvpn::install'],
    }
}
