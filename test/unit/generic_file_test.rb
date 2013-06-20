require 'test_helper'

class GenericFileTest < ActiveSupport::TestCase
  def test_should_be_valid
    assert GenericFile.new.valid?
  end
end
