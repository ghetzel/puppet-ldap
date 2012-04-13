require 'puppet'
require 'puppet/util/ldap_helper'

module Puppet::Parser::Functions
  scope = Puppet::Parser::Scope.new

# ldapgroup
#--------------------------------------------------------------------------
  describe function(:ldapgroup) do
    it "should return an array with 5 elements in it when querying cn=testgroup1" do
      scope.function_ldapgroup(['cn=testgroup1,ou=Testing']).should have(5).things
    end

    it "should throw an error when a clearly invalid DN is specified" do
      expect{ scope.function_ldapgroup(['cn=testgroup1,ou=Testing,dc=zombo,dc=com']) }.should raise_error(Puppet::ParseError)
    end
  end
end
