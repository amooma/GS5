class AddUuidToConferenceInvitee < ActiveRecord::Migration
  def change
    add_column :conference_invitees, :uuid, :string

  end
end
