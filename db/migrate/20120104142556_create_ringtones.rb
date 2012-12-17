class CreateRingtones < ActiveRecord::Migration
  def self.up
    create_table :ringtones do |t|
      t.string :ringtoneable_type
      t.integer :ringtoneable_id
      t.string :audio
      t.integer :bellcore_id
      t.timestamps
    end
  end

  def self.down
    drop_table :ringtones
  end
end
