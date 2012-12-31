require 'test_helper'

class LanguageTest < ActiveSupport::TestCase
  test "has a valid factory" do
    assert FactoryGirl.build(:language).valid?
  end
end
