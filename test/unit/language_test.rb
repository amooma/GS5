require 'test_helper'

class LanguageTest < ActiveSupport::TestCase
  test "has a valid factory" do
    assert Factory.build(:language).valid?
  end
end
