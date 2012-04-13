require 'puppet'
require 'uri'
require 'puppet/util/ldap_helper'

module Puppet::Parser::Functions
  newfunction(:ldapquery, :type => :rvalue, :doc => <<-'ENDHEREDOC') do |args|
      This function will perform a generic LDAP query to a specified server and
      return one of more results.

      Example:

        ldapquery("(mail=*@example.com)")

          This will perform an LDAP query for all objects up to one level below the
          root (default) that contain a mail attribute.  It will return an array of
          distinguished names (DNs).


        ldapquery("(mail=*@example.com)", "uid")

          This is the same as above, except it will return an array of non-empty
          values from the 'uid' attribute of each matching result.


        ldapquery("ldap:///ou=People???(uid=bob)", "cn")

          This will query the directory for all objects directly under the 'People'
          OU whose 'uid' attribute is 'bob', returning an array of 'cn' values.

          The first argument here is specified as an LDAP URL resembling the RFC 2255
          standard.  See LDAP URLs for details.


      LDAP URLs:

        The first argument to ldapquery() can either be a standard LDAP filter string,
        or a fully qualified LDAP URL.  The URL resembles the RFC 2255 format, but has
        a few additional features that make it easier to use within the context of
        Puppet.

        The format of the URL breaks down like this:

        ldap:// [HOST[:PORT]] / [BASE_DN] ? [ATTRIB[, ...]] ? SCOPE ? FILTER ? [EXTENSIONS ...]


        * HOST and PORT are optional components that specify the LDAP server to query.
          If omitted, it will default to the value of the 'ldapserver' configuration
          in puppet.conf.

        * BASE_DN is the location to begin the search from.  If omitted, it will default
          to the value of the 'ldapbase' configuration in puppet.conf.  If a DN is
          specified that does not contain at least one 'dc=' component, it is taken
          to be a relative DN (RDN).  In this case, the value of 'ldapbase' will
          automatically be appended to the supplied value.

          For example, given that puppet.conf reads:

          # -8<---------------------------------------------------------------
          [main]
          ...
          ldapbase = dc=example,dc=net 
          # -8<---------------------------------------------------------------

          The Base DN for the URL "ldap:///ou=Groups???(cn=*)" would expand
          to 'ou=Groups,dc=example,dc=net'.

        * ATTRIB is a comma-separated list of one or more attributes the search
          should return.

        * SCOPE is one of 'base', 'one', or 'sub' that specifies the scope of the 
          LDAP query to be run.  'base' will only search the object specified as BASE_DN,
          'one' will search up to one level below BASE_DN, and 'sub' will search the
          entire subtree below BASE_DN.  The default is 'one'.

        * FILTER is the LDAP Query to be run.  This component is required.

        * EXTENSIONS are a comma-separated list of key=value pairs that can be
          passed into the function for various purposes.  Currently supported
          extensions are:

          > userfact:
              the Facter fact that contains the username to be used in the LDAP bind

          > passfact:
              the Facter fact that contains the password to be used in the LDAP bind

          > timeout:
              specifies the amount of time (in seconds) before
              the query is cancelled.

          > multi:
              specifies what to do with attributes that appear multiple times
              in a result set.

              'first' - only return the first value
              'join'  - join all values on :attrDelim
              'merge' - append all values into the result set (default)

          > attrDelim:
              specifies the string to join multiple attributes on (default: comma)

    ENDHEREDOC

  # must have at least one arg
    if args.length > 0
      rv = []

    # get args
      query, attrib, firstOnly = args

    # set default for firstOnly
      firstOnly = (firstOnly == nil ? false : firstOnly)

    # open connection, process URL/filter into LDAP details
      ldap = Puppet::Util::LdapHelper.connect(query, attrib, firstOnly)

    # get username/pass or nil
      username = Facter.value(ldap[:extensions][:userfact]) if ldap[:extensions][:userfact]
      password = Facter.value(ldap[:extensions][:passfact]) if ldap[:extensions][:passfact]

    # bind
      if username && password
        conn = ldap[:connection].bind(username, password)
      else
        conn = ldap[:connection].bind()
      end

      begin
      # perform search
        conn.search(ldap[:basedn], ldap[:scope], ldap[:filter], ldap[:attributes], ldap[:extensions][:timeout].to_i || 0) do |entry|
        # if a specific attribute is specified
          if ldap[:return_attr]
          # if it exists in the result
            if entry[ldap[:return_attr]]

            # if there are more than one...
              if entry[ldap[:return_attr]].is_a?(Array)
                case ldap[:extensions][:multi].to_s
                when 'first'
                  rv << entry[ldap[:return_attr]].first
                when 'join'
                  rv << entry[ldap[:return_attr]].join(ldap[:extensions][:attrDelim] || ',')
                else
                # throw them all in the result set by default
                  rv += entry[ldap[:return_attr]]
                end
              else
                rv << entry[ldap[:return_attr]]
              end

            end
          else
          # default: add the DN
            rv << entry.dn
          end
        end
      rescue ::LDAP::ResultError => e
        raise Puppet::ParseError, ("ldapquery(): LDAP ResultError - #{e.message}")
      end    

    # sort if requested
      if ldap[:extensions][:sort]
        rv.sort!

      # reverse if desc sort
        if ldap[:extensions][:sortDir].to_s.downcase == 'desc'
          rv.reverse!
        end
      end

    # unique if requested
      if ldap[:extensions][:unique]
        rv.uniq!
      end

    # final pass to cull nulls
      rv.compact!

      return (firstOnly ? rv.first : rv)
    else
      raise Puppet::ParseError, ("ldapquery(): must provide at least one argument")
    end
  end
end
