require 'test_helper'

class GsClusterSyncLogEntryTest < ActiveSupport::TestCase
  def test_should_be_valid
    assert GsClusterSyncLogEntry.new.valid?
  end
end
