require 'test_helper'

class GuiFunctionTest < ActiveSupport::TestCase
  def test_should_be_valid
    assert GuiFunction.new.valid?
  end
end
