require 'puppet'
require 'facter'
require 'puppet/util/ldap_helper'

module Puppet::Parser::Functions
  scope = Puppet::Parser::Scope.new

# parse_ldap_url
#--------------------------------------------------------------------------
  describe function(:parse_ldap_url) do
    before(:all) do
    # parse the Puppet config
      Puppet.parse_config
    end

  # URL tests
    it "should parse a complete LDAP URL" do
      test   = "ldap://localhost:389/dc=test,dc=net?samaccountname?sub?(face=*)?arg1=val1,arg2=val2"
      result = ["localhost", 389, "dc=test,dc=net", ["samaccountname"], LDAP::LDAP_SCOPE_SUBTREE, "(face=*)", {:arg1 => 'val1', :arg2 => 'val2'}]

      Puppet::Util::LdapHelper.parse_ldap_url(test).should == result
    end

    it "should parse an LDAP URL with the port overridden" do
      test   = "ldap://localhost:1423/dc=test,dc=net?samaccountname?sub?(face=*)"
      result = ["localhost", 1423, "dc=test,dc=net", ["samaccountname"], LDAP::LDAP_SCOPE_SUBTREE, "(face=*)", {}]

      Puppet::Util::LdapHelper.parse_ldap_url(test).should == result
    end

    it "should parse an LDAP URL with the port omitted" do
      test   = "ldap://localhost:389/dc=test,dc=net?samaccountname?sub?(face=*)"
      result = ["localhost", 389, "dc=test,dc=net", ["samaccountname"], LDAP::LDAP_SCOPE_SUBTREE, "(face=*)", {}]

      Puppet::Util::LdapHelper.parse_ldap_url(test).should == result
    end

    it "should parse an LDAP URL with the port, BaseDN omitted" do
      test   = "ldap://localhost/?samaccountname?sub?(face=*)"
      result = ["localhost", 389, Facter.value('ldapbase'), ["samaccountname"], LDAP::LDAP_SCOPE_SUBTREE, "(face=*)", {}]

      Puppet::Util::LdapHelper.parse_ldap_url(test).should == result
    end

    it "should parse an LDAP URL with the port, BaseDN, attribute omitted" do
      test   = "ldap://localhost/??sub?(face=*)"
      result = ["localhost", 389, Facter.value('ldapbase'), [], LDAP::LDAP_SCOPE_SUBTREE, "(face=*)", {}]

      Puppet::Util::LdapHelper.parse_ldap_url(test).should == result
    end

    it "should parse an LDAP URL with the port, BaseDN, omitted; multiple attributes specified" do
      test   = "ldap://localhost/?pager,mail?sub?(face=*)"
      result = ["localhost", 389, Facter.value('ldapbase'), ["pager", "mail"], LDAP::LDAP_SCOPE_SUBTREE, "(face=*)", {}]

      Puppet::Util::LdapHelper.parse_ldap_url(test).should == result
    end

    it "should parse an LDAP URL with the port, BaseDN, attribute, scope omitted" do
      test   = "ldap://localhost/???(face=*)"
      result = ["localhost", 389, Facter.value('ldapbase'), [], LDAP::LDAP_SCOPE_ONELEVEL, "(face=*)", {}]

      Puppet::Util::LdapHelper.parse_ldap_url(test).should == result
    end

    it "should parse an LDAP URL with the host, port, BaseDN, attribute, scope omitted" do
      test   = "ldap:///???(face=*)"
      result = [Facter.value('ldapserver'), 389, Facter.value('ldapbase'), [], LDAP::LDAP_SCOPE_ONELEVEL, "(face=*)", {}]

      Puppet::Util::LdapHelper.parse_ldap_url(test).should == result
    end

    it "should create a fully qualified DN from a partial DN in the URL" do
      test   = "ldap:///ou=People???(face=*)"
      result = [Facter.value('ldapserver'), 389, "ou=People,"+Facter.value('ldapbase'), [], LDAP::LDAP_SCOPE_ONELEVEL, "(face=*)", {}]

      Puppet::Util::LdapHelper.parse_ldap_url(test).should == result
    end

    it "should raise an error when the filter component is omitted from the LDAP URL" do
      test   = "ldap:///???"
      expect { Puppet::Util::LdapHelper.parse_ldap_url(test) }.should raise_error(Puppet::ParseError)
    end
  end

# ldapquery
#--------------------------------------------------------------------------
  describe function(:ldapquery) do

  # + PASSING +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    it "should return an array with more than 3 elements in it when querying the directory root" do
      scope.function_ldapquery(['(ou=*)', 'ou']).should have_at_least(3).things
    end

    it "should return an array with more than 3 elements in it when querying ou=Testing" do
      scope.function_ldapquery(['ldap:///ou=Testing???(cn=*)']).should have_at_least(3).things
    end

    it "should return 'Test User 1' when asking for a single entry uid=testuser1 from ou=Testing" do
      scope.function_ldapquery(['ldap:///ou=Testing?cn??(uid=testuser1)', nil, true]).should == 'Test User 1'
    end

    it "should return an empty array querying ou=Testing for a non-existent attribute" do
      scope.function_ldapquery(['ldap:///ou=Testing???(zazzlefraz=*)']).should have(0).things
    end

    it "should return an array querying ou=Testing for a multi-attribute, returning all attributes" do
      scope.function_ldapquery(['ldap:///ou=Testing?description??(uid=testuser*)']).should have(20).things
    end

    it "should return an array querying ou=Testing for a multi-attribute, using only the first instance" do
      scope.function_ldapquery(['ldap:///ou=Testing?description??(uid=testuser*)?multi=first']).should have(5).things
    end

    it "should return an array querying ou=Testing for a multi-attribute, joining on pipe" do
      scope.function_ldapquery(['ldap:///ou=Testing?description??(uid=testuser*)?multi=join,attrDelim=%7C']).should have(5).things
    end
  end
end
