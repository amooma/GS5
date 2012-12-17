class AddAccessAuthorizationUserIdToPhoneNumber < ActiveRecord::Migration
  def change
    add_column :phone_numbers, :access_authorization_user_id, :integer

  end
end
