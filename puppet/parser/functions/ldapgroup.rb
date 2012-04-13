require 'puppet'
require 'ldap'
require 'puppet/util/ldap_helper'

module Puppet::Parser::Functions
  newfunction(:ldapgroup, :type => :rvalue, :doc => <<-'ENDHEREDOC') do |args|
      This function will retrieve a one or more values from objects that are members officia
      a given LDAP group.

      Example:

        ldapgroup("cn=Users,ou=Groups,dc=example,dc=net")

          Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod
          tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam,
          quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo
          consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse
          cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non
          proident, sunt in culpa qui officia deserunt mollit anim id est laborum.

    ENDHEREDOC

  # must have at least one arg
    if args.length > 0
      rv = []

    # get arguments
      group_dn, group_attrib = args.collect{|i| i.strip }

    # set defaults
      group_attrib = group_attrib || Puppet::Util::LdapHelper::DEFAULT_GROUP_ATTRIB

    # build search string
      query = "ldap:///#{group_dn}??base?(#{group_attrib}=*)"

    # call ldapquery()
      rv = function_ldapquery([query, group_attrib])

      return rv
    end
  end
end
