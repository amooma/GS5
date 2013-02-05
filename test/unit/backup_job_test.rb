require 'test_helper'

class BackupJobTest < ActiveSupport::TestCase
  def test_should_be_valid
    assert BackupJob.new.valid?
  end
end
