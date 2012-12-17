class FreeswitchCdr < ActiveRecord::Base
  self.table_name = 'cdrs'
  self.primary_key = 'uuid'
end
