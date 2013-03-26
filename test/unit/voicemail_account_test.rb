require 'test_helper'

class VoicemailAccountTest < ActiveSupport::TestCase
  def test_should_be_valid
    assert VoicemailAccount.new.valid?
  end
end
