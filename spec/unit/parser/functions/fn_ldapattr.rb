require 'puppet'
require 'puppet/util/ldap_helper'

module Puppet::Parser::Functions
  scope = Puppet::Parser::Scope.new

# ldapattr
#--------------------------------------------------------------------------
  describe function(:ldapattr) do
    it "should return 'Test User 3' when querying the cn attribute of uid=testuser3" do
      scope.function_ldapattr(['uid=testuser3,ou=Testing', 'cn']).should == 'Test User 3'
    end

    it "should return 'Test 3, Description ?' when querying the description attribute of uid=testuser3" do
      scope.function_ldapattr(['uid=testuser3,ou=Testing', 'description']).should match(/Test 3, Description [0-9]/)
    end

    it "should return 4 items when querying the description attribute of uid=testuser3 with multi=true" do
      scope.function_ldapattr(['uid=testuser3,ou=Testing', 'description', true]).should have(4).things
    end

    it "should return 1 string with 4 occurrences of 'Test' when querying the description attribute of uid=testuser3 with multi=<delimiter>" do
      scope.function_ldapattr(['uid=testuser3,ou=Testing', 'description', ', ']).should match(/(Test.*){4}/)
    end
  end
end
