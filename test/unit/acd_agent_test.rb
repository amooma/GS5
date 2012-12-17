require 'test_helper'

class AcdAgentTest < ActiveSupport::TestCase
  def test_should_be_valid
    assert AcdAgent.new.valid?
  end
end
