class CreatePhoneBookEntries < ActiveRecord::Migration
  def self.up
    create_table :phone_book_entries do |t|
      t.integer :phone_book_id
      t.string :first_name
      t.string :middle_name
      t.string :last_name
      t.string :title
      t.string :nickname
      t.string :organization
      t.boolean :is_organization
      t.string :department
      t.string :job_title
      t.boolean :is_male
      t.date :birthday
      t.string :birth_name
      t.string :state
      t.text :description
      t.integer :position
      t.string :homepage_personal
      t.string :homepage_organization
      t.string :twitter_account
      t.string :facebook_account
      t.string :google_plus_account
      t.string :xing_account
      t.string :linkedin_account
      t.string :mobileme_account
      t.timestamps
    end
  end

  def self.down
    drop_table :phone_book_entries
  end
end
