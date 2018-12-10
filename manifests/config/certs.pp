#
# == Define: openvpn::config::certs
#
# Setup OpenVPN keys, certificates, static keys and Diffie-Hellman parameters. 
# Some parts of the configuration can be omitted when using Puppet certificates 
# or when configuring OpenVPN clients.
#
# == Parameters
#
# [*manage_dh*]
#   Whether to manage Diffie-Hellman parameters. Valid values are true and false 
#   On OpenVPN servers this needs to be set to true.
# [*manage_certs*]
#   Whether to manage OpenVPN certificates and keys generated using some 
#   external CA such as Easy-RSA 3. Valid values are true and false.
# [*manage_client_certs*]
#   Manage client's private key and certificate. Valid values are true and 
#   false.
# [*role*]
#   Connection type. Either 'client' or 'server'. Affects location of the
#   certificate files on some platforms.
#
define openvpn::config::certs
(
    Boolean                 $manage_dh,
    Boolean                 $manage_certs,
    Boolean                 $manage_client_certs,
    Enum['client','server'] $role,
    Optional[String]        $files_baseurl = undef,
)
{
    $l_files_baseurl = openvpn::baseurl($files_baseurl)

    if $::openvpn::params::config_split {
        $basedir = $role ? {
            'client' => $::openvpn::params::client_config_dir,
            'server' => $::openvpn::params::server_config_dir,
        }
    } else {
        $basedir = $::openvpn::params::config_dir
    }

    # Special case path for Windows
    $config_dir = $::kernel ? {
        'windows' => "${basedir}\\",
        default   => "${basedir}/"
    }

    # Use conveniently short variable names to improve readability
    $dh = "${title}-dh.pem"
    $ta = "${title}-ta.key"
    $cert = "${title}.crt"
    $key = "${title}.key"
    $ca = "${title}-ca.crt"

    $dh_path = "${config_dir}${dh}"
    $ta_path = "${config_dir}${ta}"
    $cert_path = "${config_dir}${cert}"
    $key_path = "${config_dir}${key}"
    $ca_path = "${config_dir}${ca}"

    File {
        owner   => $::os::params::adminuser,
        group   => $::os::params::admingroup,
        mode    => '0644',
        require => Class['openvpn::install'],
    }

    # Always manage the TLS auth key
    file { "openvpn-${ta}":
        name   => $ta_path,
        source => "${l_files_baseurl}/openvpn-${ta}",
        mode   => '0600',
    }

    if $manage_dh {
        file { "openvpn-${dh}":
            name   => $dh_path,
            source => "${l_files_baseurl}/openvpn-${dh}",
        }
    }

    if $manage_certs {
        file { "openvpn-${ca}":
            name   => $ca_path,
            source => "${l_files_baseurl}/openvpn-${ca}",
        }
        if $manage_client_certs {
            file { "openvpn-${cert}":
                name   => $cert_path,
                source => "${l_files_baseurl}/openvpn-${title}-${::fqdn}.crt",
            }
            file { "openvpn-${key}":
                name   => $key_path,
                source => "${l_files_baseurl}/openvpn-${title}-${::fqdn}.key",
                mode   => '0600',
            }
        }
    }
}
