require 'test_helper'

class ConferenceTest < ActiveSupport::TestCase
  
  def test_should_have_a_valid_factory
    assert Factory.build(:conference).valid?
  end
  
  def test_dates_must_make_sense
    # We can't create a conference in the past.
    assert !Factory.build(:conference, :start => Time.now - 1.day, :end => Time.now + 1.day).valid?
    
    # But we can create a conference which started 2 minutes ago.
    assert Factory.build(:conference, :start => Time.now - 2.minutes, :end => Time.now + 1.hour).valid?
    
    # The end must be before the start.
    assert !Factory.build(:conference, :start => Time.now + 2.day, :end => Time.now + 1.day).valid?
    
    # No date at all is fine.
    assert Factory.build(:conference, :start => nil, :end => nil).valid?
    
    # Just start or just end is not ok.
    assert !Factory.build(:conference, :start => nil, :end => Time.now + 1.day).valid?
    assert !Factory.build(:conference, :start => Time.now + 1.day, :end => nil).valid?
  end
  
  def test_pin_must_be_nil_or_more_than_6_digits
    conference = Factory.build(:conference, :pin => nil)
    
    assert conference.valid?
    
    (MINIMUM_PIN_LENGTH - 1).times do |i|
      pin = "#{10**i}"
      conference.pin = pin
      assert !conference.valid?      
    end
    
    conference.pin = "#{10**(MINIMUM_PIN_LENGTH - 1)}"
    assert conference.valid? 

    conference.pin = "-#{10**(MINIMUM_PIN_LENGTH - 1)}"
    assert !conference.valid?     
    
    conference.pin = 'Teststring'
    assert !conference.valid?     
  end
  
end
