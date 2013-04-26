class GenericFile < ActiveRecord::Base
  FILE_TYPES = %w(pdf ps jpg gif png tif wav mp3)
  CATEGORIES = %w(file document image greeting recording)

  attr_accessible :name, :file, :file_type, :category, :owner_id, :owner_type

  mount_uploader :file, GenericFileUploader

  belongs_to :owner, :polymorphic => true

  validates :name,
            :presence => true,
            :uniqueness => {:scope => [:owner_id, :owner_type]}

  validates :file,
            :presence => true

  before_save :determine_file_type

  def store_dir
    "/var/opt/gemeinschaft/generic_files/#{self.id.to_i}"
  end

  def mime_type
    return GenericFile.mime_type(self.file.to_s)
  end

  def self.mime_type(file_name)
    mime_type = `file -b --mime-type "#{file_name}"`.strip
    if mime_type.blank?
      mime_type = MIME::Types.type_for(file_name).first.to_s
    end

    return mime_type
  end

  def file_size
    if self.file
      return File.size(self.file.to_s)
    else
      return 0
    end
  end

  def file_extension
    mime_type = Mime::LOOKUP[self.file_type]
    if mime_type.class == Mime::Type
      return mime_type.symbol
    end
  end

  private
  def determine_file_type
    if self.file_changed?
      self.file_type = self.mime_type
    end
  end
end
