#
# == Define: openvpn::client::generic
#
# Generic parts of OpenVPN client configuration. In theory this define should
# only do stuff that is required by both static and dynamic OpenVPN configs, but
# for various reasons that became too hairy. So, right now, this class simply
# adjusts its behavior based on parameters it's given.
#
define openvpn::client::generic
(
    Boolean           $manage_packetfilter,
    Boolean           $manage_monit,
    Boolean           $dynamic,
    Boolean           $enable_service = true,
    String            $tunif='tun10',
    Optional[String]  $remote_ip = undef,
    Optional[Integer] $remote_port = undef,
    Optional[String]  $clientname = undef,
    Optional[String]  $up_script = undef,
    Optional[String]  $down_script = undef
)
{
    include ::openvpn::params

    # Shorthand for config file extension
    $ext = $::openvpn::params::config_ext

    # Configure up and down scripts as necessary
    $up_line = $up_script ? {
        undef   => undef,
        default => "up ${up_script}",
    }
    $down_line = $down_script ? {
        undef   => undef,
        default => "down ${down_script}",
    }

    # Determine whether to build the configuration file, or to use a static file 
    # from the puppet fileserver
    if $dynamic {
        $source = undef
        $content = template('openvpn/openvpn-client.conf.erb')
    } else {
        # Allow reusing generic configuration files, or certificates meant for 
        # other nodes.
        $source = $clientname ? {
            undef   => "puppet:///files/openvpn-${title}-${::fqdn}.conf",
            default => "puppet:///files/openvpn-${title}-${clientname}.conf",
        }
        $content = undef
    }

    # Special case path for Windows
    $config = $::kernel ? {
        'windows' => "${::openvpn::params::config_dir}\\${title}.${ext}",
        default   => "${::openvpn::params::config_dir}/${title}.${ext}"
    }

    # On systemd we don't have to play tricks with file extensions; instead we 
    # play tricks with links, because enabling individual OpenVPN connections 
    # using systemctl does not work due to systemd's internal limitations:
    #
    # <https://bugzilla.redhat.com/show_bug.cgi?id=746472>
    # <https://ask.fedoraproject.org/en/question/23085/how-to-start-openvpn-service-at-boot-time/>
    #
    if str2bool($::has_systemd) {

        # Add the configuration file
        file { "openvpn-${title}.conf":
            ensure  => present,
            name    => $config,
            source  => $source,
            content => $content,
            owner   => $::os::params::adminuser,
            group   => $::os::params::admingroup,
            mode    => '0644',
            require => Class['openvpn::install'],
        }

        if $enable_service {
            file { "openvpn@${title}.service":
                ensure  => link,
                path    => "/etc/systemd/system/multi-user.target.wants/openvpn@${title}.service",
                target  => '/usr/lib/systemd/system/openvpn@.service',
                require => File["openvpn-${title}.conf"],
            }
        } else {
            file { "openvpn@${title}.service":
                ensure => absent,
                path   => "/etc/systemd/system/multi-user.target.wants/openvpn@${title}.service",
            }
        }

    # There is no common way to enable and disable individual VPN connections on 
    # non-systemd distros. This trickery is probably the best we can do without 
    # complexity going through the roof.
    } else {
        if $enable_service {
            $active_config = "${::openvpn::params::config_dir}/${title}.${ext}"
            $inactive_config = "${::openvpn::params::config_dir}/${title}.${ext}.disabled"
        } else {
            $active_config = "${::openvpn::params::config_dir}/${title}.${ext}.disabled"
            $inactive_config = "${::openvpn::params::config_dir}/${title}.${ext}"
        }

        # Add the active configuration file
        file { "openvpn-${title}.conf-active":
            ensure  => present,
            name    => $active_config,
            source  => $source,
            content => $content,
            owner   => $::os::params::adminuser,
            group   => $::os::params::admingroup,
            mode    => '0644',
            require => Class['openvpn::install'],
        }

        # Remove the inactive configuration file (if we switched from 
        # $enable_service = true to false, or vice versa.
        file { "openvpn-${title}.conf-inactive":
            ensure  => absent,
            name    => $inactive_config,
            require => File["openvpn-${title}.conf-active"],
            notify  => Class['openvpn::service'],
        }
    }

    if $manage_monit {
        openvpn::monit { $title:
            enable_service => $enable_service,
        }
    }

    if $manage_packetfilter {
        openvpn::packetfilter::common { "openvpn-${title}":
            tunif => $tunif,
        }
    }
}
