class PopulateUuidField < ActiveRecord::Migration
  def up
    AccessAuthorization.where('uuid IS NULL OR uuid = ""').each do |record|
      uuid = UUID.new
      record.uuid = uuid.generate
      record.save
    end

    AcdAgent.where('uuid IS NULL OR uuid = ""').each do |record|
      uuid = UUID.new
      record.uuid = uuid.generate
      record.save
    end

    AutomaticCallDistributor.where('uuid IS NULL OR uuid = ""').each do |record|
      uuid = UUID.new
      record.uuid = uuid.generate
      record.save
    end

    Callthrough.where('uuid IS NULL OR uuid = ""').each do |record|
      uuid = UUID.new
      record.uuid = uuid.generate
      record.save
    end

    ConferenceInvitee.where('uuid IS NULL OR uuid = ""').each do |record|
      uuid = UUID.new
      record.uuid = uuid.generate
      record.save
    end

    Conference.where('uuid IS NULL OR uuid = ""').each do |record|
      uuid = UUID.new
      record.uuid = uuid.generate
      record.save
    end

    FaxAccount.where('uuid IS NULL OR uuid = ""').each do |record|
      uuid = UUID.new
      record.uuid = uuid.generate
      record.save
    end

    FaxDocument.where('uuid IS NULL OR uuid = ""').each do |record|
      uuid = UUID.new
      record.uuid = uuid.generate
      record.save
    end

    HuntGroupMember.where('uuid IS NULL OR uuid = ""').each do |record|
      uuid = UUID.new
      record.uuid = uuid.generate
      record.save
    end

    HuntGroup.where('uuid IS NULL OR uuid = ""').each do |record|
      uuid = UUID.new
      record.uuid = uuid.generate
      record.save
    end

    PhoneBookEntry.where('uuid IS NULL OR uuid = ""').each do |record|
      uuid = UUID.new
      record.uuid = uuid.generate
      record.save
    end

    PhoneNumberRange.where('uuid IS NULL OR uuid = ""').each do |record|
      uuid = UUID.new
      record.uuid = uuid.generate
      record.save
    end

    PhoneNumber.where('uuid IS NULL OR uuid = ""').each do |record|
      uuid = UUID.new
      record.uuid = uuid.generate
      record.save
    end

    SipAccount.where('uuid IS NULL OR uuid = ""').each do |record|
      uuid = UUID.new
      record.uuid = uuid.generate
      record.save
    end

    Tenant.where('uuid IS NULL OR uuid = ""').each do |record|
      uuid = UUID.new
      record.uuid = uuid.generate
      record.save
    end

    User.where('uuid IS NULL OR uuid = ""').each do |record|
      uuid = UUID.new
      record.uuid = uuid.generate
      record.save
    end
 
    PhoneBook.where('uuid IS NULL OR uuid = ""').each do |record|
      uuid = UUID.new
      record.uuid = uuid.generate
      record.save
    end

    Address.where('uuid IS NULL OR uuid = ""').each do |record|
      uuid = UUID.new
      record.uuid = uuid.generate
      record.save
    end

    CallForward.where('uuid IS NULL OR uuid = ""').each do |record|
      uuid = UUID.new
      record.uuid = uuid.generate
      record.save
    end

    PhoneModel.where('uuid IS NULL OR uuid = ""').each do |record|
      uuid = UUID.new
      record.uuid = uuid.generate
      record.save
    end

    Softkey.where('uuid IS NULL OR uuid = ""').each do |record|
      uuid = UUID.new
      record.uuid = uuid.generate
      record.save
    end

    Whitelist.where('uuid IS NULL OR uuid = ""').each do |record|
      uuid = UUID.new
      record.uuid = uuid.generate
      record.save
    end
  end

  def down
  end
end
