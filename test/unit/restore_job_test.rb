require 'test_helper'

class RestoreJobTest < ActiveSupport::TestCase
  def test_should_be_valid
    assert RestoreJob.new.valid?
  end
end
