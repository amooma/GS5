require 'test_helper'

class GsNodeTest < ActiveSupport::TestCase
  def test_should_be_valid
    assert GsNode.new.valid?
  end
end
