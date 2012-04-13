require 'ldap'
require 'facter'

module Puppet::Util::LdapHelper
  DEFAULT_SCOPE = 'one'
  DEFAULT_GROUP_ATTRIB = 'uniqueMember'

  def self.connect(query, attrib=nil, firstOnly=false)
  # load puppet config
    Puppet.parse_config

  # if a full URL is not specified (filter only), build out a minimal URL
    if not Puppet::Util::LdapHelper.is_ldap_url?(query)
      query = "ldap:///?#{attrib}??#{query}?"
    end

  # parse out URL values
    _server, _port, _dn, _attrs, _scope, _filter, _ext = Puppet::Util::LdapHelper.parse_ldap_url(query)


  # sanitize attrib (empty string becomes nil)
    attrib = nil if attrib && attrib.empty?

  # if an attribute was not specified as an argument, was at least one was
  # given in the URL, use the first one specified there
    if not (attrib || _attrs.empty?)
      attrib = _attrs.first
    end

  # connect
    conn = ::LDAP::Conn.new(_server, _port)

    {
      :connection  => conn,
      :server      => _server,
      :port        => _port,
      :basedn      => _dn,
      :attributes  => _attrs,
      :return_attr => attrib,
      :scope       => _scope,
      :filter      => _filter,
      :extensions  => _ext
    }
  end

  def self.is_ldap_url?(value)
    (value =~ /^ldap\:\/\//)
  end

  def self.parse_ldap_url(url)
  # get puppet ldap settings
    pp_ldap_server = Facter.value('ldapserver') || Puppet.settings['ldapserver']
    pp_ldap_base   = Facter.value('ldapbase') || Puppet.settings['ldapbase']

  # parse out host section
    host, qs = url.split('/')[2,3]
    host = pp_ldap_server if host.to_s.empty?
    _server, _port = host.split(':')
    _port = ::LDAP::LDAP_PORT if _port.to_s.empty?

  # parse out the rest
    qs = qs.split('?')
    _dn, _attrs, _scope, _filter = qs
    _ext = {}
    
  # if the 5th segment is filled in (EXTENSIONS), convert it to a hash
    if qs.length >= 5
    # extensions are comma separated
      qs.last.split(',').each do |ext|
        key, val = ext.split('=')
        _ext[key.to_s.to_sym] = URI.unescape(val)
      end
    end

  # handle "relative" BaseDNs, which will append the user-specified DN components
  # to the system's base DN.
    if not _dn.to_s.empty?
      if not _dn.to_s.split(',').collect{|i| i.split('=').first.downcase }.include?("dc")
        _dn = "#{_dn},#{pp_ldap_base}"
      end
    end

  # set defaults
    _dn = pp_ldap_base if _dn.to_s.empty?
    _attrs = _attrs.to_s
    _scope = DEFAULT_SCOPE if _scope.to_s.empty?
    raise Puppet::ParseError, ("ldapquery(): must provide an LDAP search filter") if _filter.to_s.empty?


  # fixup scope, convert to ldap internals
    case _scope.downcase
    when 'one'
      _scope = ::LDAP::LDAP_SCOPE_ONELEVEL
    when 'sub'
      _scope = ::LDAP::LDAP_SCOPE_SUBTREE
    else
      _scope = ::LDAP::LDAP_SCOPE_BASE
    end

  # values are now properly sanitized, return them
    [_server, _port.to_i, _dn, _attrs.split(','), _scope, _filter, _ext]
  end
end