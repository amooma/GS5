require 'test_helper'

class AcdCallerTest < ActiveSupport::TestCase
  def test_should_be_valid
    assert AcdCaller.new.valid?
  end
end
