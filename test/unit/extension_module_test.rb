require 'test_helper'

class ExtensionModuleTest < ActiveSupport::TestCase
  def test_should_be_valid
    assert ExtensionModule.new.valid?
  end
end
