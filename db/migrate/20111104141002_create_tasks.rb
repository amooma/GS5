class CreateTasks < ActiveRecord::Migration
  def self.up
    create_table :tasks, :id => false do |t|
      t.integer :task_id,                         :primary => true
      t.string  :task_desc,       :limit=>'4096'
      t.string  :task_group,      :limit=>'1024'
      t.integer :task_sql_manager
      t.string  :hostname,        :limit=>'256'
    end
    add_index :tasks, [ :hostname, :task_id ], :unique => true, :name => 'tasks1'
  end

  def self.down
    drop_table :tasks
  end
end
