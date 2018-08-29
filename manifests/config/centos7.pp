#
# == Class: openvpn::config::centos7
#
# Enable pid-file on CentOS 7
#
class openvpn::config::centos7 inherits openvpn::params {

    $services = ['openvpn','openvpn-client','openvpn-server']

    $services.each |$service| {
        ::systemd::service_fragment { "${service}@":
            ensure        => 'present',
            service_name  => "${service}@",
            template_path => 'openvpn/openvpn@.service.centos7.erb',
        }
    }
}
