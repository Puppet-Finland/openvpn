#
# == Class: openvpn
#
# Class for setting up OpenVPN.
#
# Each server and client instance (=VPN connection) is configured separately in 
# openvpn::serverinstance and openvpn::clientinstance.
#
# == Parameters
#
# [*use_latest_release*]
#   This parameter has been removed, and if it is set to true, the puppet run 
#   will fail with an error message.
# [*repository*]
#   The OpenVPN repository to use. This can be one of 'stable', 'testing', 
#   'release/2.3', 'release/2.4' or undef (default). Undef means that openvpn 
#   from the distribution's default repositories is used. This parameter only 
#   has an effect on Debian-based operating systems.
# [*enable_service*]
#   Enable OpenVPN service on boot. Valid values are true (default) and false. 
#   This only affects non-systemd distros which may or may not have built-in 
#   fine-grained control over which VPN connections to start.
# [*ensure_service*]
#   State of the system service. Valid values are 'running' and undef (default).
#   This does not have any effect on systemd distros where each OpenVPN config
#   is a separate system service.
# [*inline_clients*]
#   A hash of openvpn::client::inline resources to realize.
# [*passwordauth_clients*]
#   A hash of openvpn::client::passwordauth resources to realize.
# [*dynamic_clients*]
#   A hash of openvpn::client::dynamic resources to realize.
# [*inline_servers*]
#   A hash of openvpn::server::inline resources to realize.
# [*ldapauth_servers*]
#   A hash of openvpn::server::ldapauth resources to realize.
# [*dynamic_servers*]
#   A hash of openvpn::server::dynamic resources to realize.
#
# == Authors
#
# Samuli Seppänen <samuli.seppanen@gmail.com>
#
# Samuli Seppänen <samuli@openvpn.net>
#
# Mikko Vilpponen <vilpponen@protecomp.fi>
#
# == License
#
# BSD-license. See file LICENSE for details.
#
class openvpn
(
    Boolean $use_latest_release = false,
            $repository = undef,
            $enable_service = true,
            $ensure_service = undef,
    Hash    $inline_clients = {},
    Hash    $passwordauth_clients = {},
    Hash    $dynamic_clients = {},
    Hash    $inline_servers = {},
    Hash    $ldapauth_servers = {},
    Hash    $dynamic_servers = {}

) inherits openvpn::params
{

    if $use_latest_release {
        fail('ERROR: parameter $use_latest_release is invalid, please use $repository instead!')
    }

    # Parts that work on all supported platforms
    include ::openvpn::install

    # We need to include openvpn::softwarerepo to be able to create proper 
    # dependencies in openvpn::install, whether we add any custom software 
    # repositories or not.
    #
    class { '::openvpn::softwarerepo':
        repository => $repository,
    }

    include ::openvpn::install

    # Most systemd distros do not create pidfiles by default -> fix.
    #
    # Regexps require string values on both sides, so we need first to
    # check for presence of $::lsbdistcodename.
    if $::lsbdistcodename {
        if $::lsbdistcodename =~ /^(jessie|stretch)$/ {
            ::openvpn::config::systemd { $::lsbdistcodename: }
        }
    }
    if ($facts['os']['family'] == 'RedHat') and ($facts['os']['release']['major'] == '7') {
        include ::openvpn::config::centos7
    }

    class { '::openvpn::service':
        ensure => $ensure_service,
        enable => $enable_service,
    }

    create_resources('openvpn::client::inline', $inline_clients)
    create_resources('openvpn::client::passwordauth', $passwordauth_clients)
    create_resources('openvpn::client::dynamic', $dynamic_clients)

    # We only have limited support for Windows
    unless $::kernel == 'windows' {

        create_resources('openvpn::server::inline', $inline_servers)
        create_resources('openvpn::server::ldapauth', $ldapauth_servers)
        create_resources('openvpn::server::dynamic', $dynamic_servers)
    }

    # Realize monit configuration fragments
    File <| tag == 'monit' |>
}
