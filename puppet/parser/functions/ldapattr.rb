require 'puppet'
require 'ldap'
require 'uri'
require 'puppet/util/ldap_helper'

module Puppet::Parser::Functions
  newfunction(:ldapattr, :type => :rvalue, :doc => <<-'ENDHEREDOC') do |args|
      This function will retrieve an attribute from an LDAP object.

      Example:

        ldapattr("uid=joe,ou=People,dc=example,dc=net", "mail")

          Retrieve the value of the first 'mail' attribute from the given DN.


        ldapattr("uid=joe,ou=People,dc=example,dc=net", "mail", true)

          Retrieve the values of all 'mail' attributes from the given DN as an array.


        ldapattr("uid=joe,ou=People,dc=example,dc=net", "mail", ", ")

          Retrieve all 'mail' attributes, return a string of all values joined by
          the string ', '.

    ENDHEREDOC

  # must have at least two args
    if args.length > 1
      rv = []

    # get arguments
      _dn, _attrib, _joinMulti = args
      _joinMulti = URI.unescape(_joinMulti) if _joinMulti.is_a?(String)
      multi = false

    # build search string
      query = "ldap:///#{_dn}?#{_attrib}?base?(#{_attrib}=*)"
      
    # for join-boolean-true arg3
      if _joinMulti == true || _joinMulti =~ /^(true|t|yes|1)$/i
        multi = true

      elsif not _joinMulti.to_s.empty?
    # for join-delimiter
        query += "?multi=join,attrDelim=#{URI.escape(URI.escape(_joinMulti.to_s), ",")}"
      end

    # call ldapquery()
      function_ldapquery([query, _attrib, !multi])
    end
  end
end
