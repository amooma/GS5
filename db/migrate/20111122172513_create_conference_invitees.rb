class CreateConferenceInvitees < ActiveRecord::Migration
  def self.up
    create_table :conference_invitees do |t|
      t.integer :conference_id
      t.integer :phone_book_entry_id
      t.string :pin
      t.boolean :speaker
      t.boolean :moderator
      t.timestamps
    end
  end

  def self.down
    drop_table :conference_invitees
  end
end
