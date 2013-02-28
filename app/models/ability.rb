class Ability
  include CanCan::Ability
  
  def initialize( user )
    # See the wiki for details: https://github.com/ryanb/cancan/wiki/Defining-Abilities
    if user && user.current_tenant != nil
      if GemeinschaftSetup.count == 1 && Tenant.count == 1 && User.count == 1 && UserGroup.count == 1
        # This is a new installation with a Master-Tenant and a Super-Admin.
        #
        can [:read, :create], Tenant
      else
        tenant = user.current_tenant

        if user.current_tenant.user_groups.where(:name => 'Admins').first \
          && user.current_tenant.user_groups.where(:name => 'Admins').first.users.include?(user)
          # ADMIN ABILITIES
          # With great power comes great responsibility!
          #
          can :manage, :all

          # Manufacturers and PhoneModels can not be changed
          #
          cannot [:create, :destroy, :edit, :update], Manufacturer
          cannot [:create, :destroy, :edit, :update], PhoneModel

          # Super-Tenant can not be destroyed or edited
          #
          cannot [:create, :destroy, :edit, :update], Tenant, :id => 1

          # Can't destroy any tenant
          #
          cannot :destroy, Tenant

          cannot :manage, PhoneBook

          # Phonebooks and PhoneBookEntries
          #
          can :manage, PhoneBook, :phone_bookable_type => 'Tenant', :phone_bookable_id => tenant.id
          can :manage, PhoneBookEntry, :phone_book => { :phone_bookable_type => 'Tenant', :phone_bookable_id => tenant.id }

          can :manage, PhoneBook, :phone_bookable_type => 'UserGroup', :phone_bookable_id => tenant.user_group_ids
          tenant.user_groups.each do |user_group|
            can :manage, PhoneBookEntry, :phone_book => { :id => user_group.phone_book_ids }
          end

          # Personal Phonebooks and PhoneBookEntries
          #
          can :manage, PhoneBook, :phone_bookable_type => 'User', :phone_bookable_id => user.id
          can :manage, PhoneBookEntry, :phone_book => { :phone_bookable_type => 'User', :phone_bookable_id => user.id }

          can :read, PhoneBook, :phone_bookable_type => 'Tenant', :phone_bookable_id => tenant.id
          can :read, PhoneBookEntry, :phone_book => { :phone_bookable_type => 'Tenant', :phone_bookable_id => tenant.id }

          can :read, PhoneBook, :phone_bookable_type => 'UserGroup', :phone_bookable_id => user.user_group_ids
          user.user_groups.each do |user_group|
            can :read, PhoneBookEntry, :phone_book => { :id => user_group.phone_book_ids }
          end

          # A FacDocument can't be changed
          #
          cannot [:edit, :update], FaxDocument

          # Backups can't be edited
          #
          cannot [:edit, :update], BackupJob

          # Can manage GsNodes
          #
          can :manage, GsNode

          # Can't phones/1/phone_sip_accounts/1/edit
          #
          cannot :edit, PhoneSipAccount

          # Dirty hack to disable PhoneNumberRange in the GUI
          #
          if GsParameter.get('STRICT_INTERNAL_EXTENSION_HANDLING') == false
            cannot :manage, PhoneNumberRange
          end

          # GsParameter and GuiFunction can't be created or deleted via the GUI
          #
          cannot [:create, :destroy], GsParameter
          cannot [:create, :destroy], GuiFunction

          # An admin can not destroy his/her account
          #
          cannot [:destroy], User, :id => user.id

          # SIM cards
          #
          cannot [:edit, :update], SimCard

          # Restore is only possible on a new system.
          #
          cannot :manage, RestoreJob

        else
          # Any user can do the following stuff.
          #

          # Own Tenant and own User
          #
          can :read, Tenant, :id => user.current_tenant.id
          can [ :read, :edit, :update ], User, :id => user.id

          # Destroy his own avatar
          #
          can :destroy_avatar, User, :id => user.id

          # Phonebooks and PhoneBookEntries
          #
          cannot :manage, PhoneBook

          can :manage, PhoneBook, :phone_bookable_type => 'User', :phone_bookable_id => user.id
          can :manage, PhoneBookEntry, :phone_book => { :phone_bookable_type => 'User', :phone_bookable_id => user.id }
          can :manage, PhoneNumber, :phone_numberable_type => 'PhoneBookEntry', :phone_numberable_id => user.phone_books.map{ |phone_book| phone_book.phone_book_entry_ids}.flatten

          can :read, PhoneBook, :phone_bookable_type => 'Tenant', :phone_bookable_id => tenant.id
          can :read, PhoneBookEntry, :phone_book => { :phone_bookable_type => 'Tenant', :phone_bookable_id => tenant.id }

          can :read, PhoneBook, :phone_bookable_type => 'UserGroup', :phone_bookable_id => user.user_group_ids
          user.user_groups.each do |user_group|
            can :read, PhoneBookEntry, :phone_book => { :id => user_group.phone_book_ids }
          end

          # UserGroups
          #
          can :read, UserGroupMembership, :user_id => user.id
          can :read, UserGroup, :users => { :user_group_memberships => { :user_id => user.id }}

          # SipAccounts and Phones
          #
          can :read, SipAccount, :sip_accountable_type => 'User', :sip_accountable_id => user.id
          user.sip_accounts.each do |sip_account|
            can :read, PhoneNumber, :id => sip_account.phone_number_ids
            can :manage, CallForward, :call_forwardable_id => sip_account.phone_number_ids
            can :manage, Ringtone, :ringtoneable_type => 'PhoneNumber', :ringtoneable_id => sip_account.phone_number_ids
            can :manage, Ringtone, :ringtoneable_type => 'SipAccount', :ringtoneable_id => sip_account.id
            can [:read, :destroy, :call] , CallHistory, :id => sip_account.call_history_ids
          end
          can :read, Phone, :phoneable_type => 'User', :phoneable_id => user.id

          # Softkeys
          #
          can :manage, Softkey, :sip_account => { :id => user.sip_account_ids }

          # Fax
          #
          can :read, FaxAccount, :fax_accountable_type => 'User', :fax_accountable_id => user.id
          user.fax_accounts.each do |fax_account|
            can :read, PhoneNumber, :id => fax_account.phone_number_ids
            can [:read, :create, :delete], FaxDocument, :fax_account_id => fax_account.id
          end 

          # Conferences
          #
          can [ :read, :edit, :update, :destroy ], Conference, :id => user.conference_ids
          user.conferences.each do |conference|
            can :read, PhoneNumber, :id => conference.phone_number_ids
            can :manage, ConferenceInvitee, :conference_id => conference.id
          end

          # User can manage CallForwards of the PhoneNumbers of his
          # own SipAccounts:
          #
          can :manage, CallForward, :call_forwardable_id => user.phone_number_ids

          # SoftkeyFunctions
          #
          can :read, SoftkeyFunction

          # Voicemail
          #
          can :manage, VoicemailMessage
          can :manage, VoicemailSetting
        end
      end
    else
      if GemeinschaftSetup.count == 0 && Tenant.count == 0 && User.count == 0
        # This is a fresh system.
        #
        can :create, GemeinschaftSetup
        can :manage, SipDomain
        can [:create, :new, :show, :index], RestoreJob
      end
    end

  end
end
