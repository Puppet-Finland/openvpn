#
# == Define: openvpn::config::systemd
#
# Some operating systems like Debian 8 do not create pidfiles for OpenVPN 
# instances by default. This would normally be ok, but we want to be able to 
# monitor the connections using monit, which depends on pidfiles.
#
# == Parameters
#
# [*title*]
#   The title of the resource defines the systemd unit file template file to 
#   use.
#
define openvpn::config::systemd {

    include ::openvpn::params
    include ::systemd

    $services = ['openvpn','openvpn-client','openvpn-server']

    $services.each |$service| {
        systemd::service_override { "openvpn-${service}@.service.${title}":
            ensure        => 'present',
            service_name  => "${service}@",
            template_path => "openvpn/openvpn@.service.${title}.erb",
        }
    }
}
