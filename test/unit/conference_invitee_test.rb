require 'test_helper'

class ConferenceInviteeTest < ActiveSupport::TestCase
  
  def test_should_have_a_valid_factory
    assert Factory.build(:conference_invitee).valid?
  end
  
  test "parent conference should not have a phone number twice" do
    invitee = Factory.create(:conference_invitee)
    conference = invitee.conference
    phone_number = PhoneNumber.new(:number => invitee.phone_number.number)
    invitee_bad = conference.conference_invitees.build(:phone_number => phone_number)
    assert !invitee_bad.valid?    
  end
  
end
