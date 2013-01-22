require 'test_helper'

class GsParameterTest < ActiveSupport::TestCase
  def test_should_be_valid
    assert GsParameter.new.valid?
  end
end
