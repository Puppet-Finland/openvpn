#
# == Define: openvpn::server::generic
#
# Generic parts of OpenVPN server configuration. Most of the parameters 
# can/should be ignored when using static configuration files.
#
# == Parameters
#
# [*title*]
#   The resource title is used as the basename for various files and
#   directories.
# [*dynamic*]
#   Whether to crate a dynamic configuration file from the module template 
#   directory, or use a static one stored on the Puppet fileserver. Valid values 
#   are true (default) and false. If this is set to false, many of the 
#   parameters in this define are not used for anything, and can be ignored.
#
define openvpn::server::generic
(
    Boolean                 $manage_packetfilter,
    Boolean                 $manage_monit,
    Boolean                 $dynamic,
    Optional[String]        $files_baseurl = undef,
    String                  $tunif = 'tun5',
    Optional[String]        $vpn_network = undef,
    Optional[String]        $vpn_netmask = undef,
    Optional[Integer]       $max_clients = undef,
    Optional[Integer]       $local_port = undef,
    Optional[Array[String]] $routes = undef,
    Optional[Array[String]] $push = undef,
    Optional[Hash]          $nat = undef
)
{
    include ::openvpn::params

    $l_files_baseurl = openvpn::baseurl($files_baseurl)

    # IP forwarding is needed if we want to access servers behind the VPN server
    # from VPN clients. For details, see
    #
    # <http://openvpn.net/index.php/open-source/documentation/howto.html#scope>
    #
    # This depends on duritong-sysctl or a compatible sysctl module
    #
    ensure_resource('sysctl::value', 'net.ipv4.ip_forward', { 'value' => 1 })

    File {
        owner   => $::os::params::adminuser,
        group   => $::os::params::admingroup,
        seluser => $::openvpn::params::seluser,
        selrole => $::openvpn::params::selrole,
        seltype => $::openvpn::params::seltype,
        require => Class['openvpn::install'],
    }

    file { "/etc/openvpn/openvpn-${title}-status.log":
        seltype => $::openvpn::params::seltype_rw,
    }

    # Setup the ccd directory
    file { "openvpn-${title}-ccd":
        ensure => directory,
        name   => "${::openvpn::params::config_dir}/${title}-ccd",
        mode   => '0755',
    }

    # Determine whether to build the configuration file, or use a static file 
    # from the puppet fileserver
    if $dynamic {
        $source = undef
        $content = template('openvpn/openvpn-server.conf.erb')
    } else {
        $source = "${l_files_baseurl}/openvpn-${title}-${::fqdn}.conf"
        $content = undef
    }

    if $::openvpn::params::config_split {
        $basedir = $::openvpn::params::server_config_dir
    } else {
        $basedir = $::openvpn::params::config_dir
    }

    $config = "${basedir}/${title}.conf"

    # Add the active configuration file
    file { "openvpn-${title}.conf":
        ensure  => present,
        name    => $config,
        source  => $source,
        content => $content,
        mode    => '0644',
    }

    # Enable the service by default - it is unlikely that we'd want to launch 
    # server instances manually.
    $service = $::openvpn::params::server_service
    if $::systemd {
        file { "openvpn@${title}.service":
            ensure  => link,
            path    => "/etc/systemd/system/multi-user.target.wants/${service}@${title}.service",
            target  => "/usr/lib/systemd/system/${service}@.service",
            require => File["openvpn-${title}.conf"],
        }
    }

    if $manage_packetfilter {
        openvpn::packetfilter::common { $title:
            tunif => $tunif,
        }
        openvpn::packetfilter::server { $title:
            tunif      => $tunif,
            local_port => $local_port,
            nat        => $nat,
        }
    }

    if $manage_monit {
        $monit_service_type = $::openvpn::params::config_split ? {
            true    => 'server',
            default => undef,
        }
        openvpn::monit { $title:
            enable_service => true,
            service_type   => $monit_service_type,
        }
    }
}
