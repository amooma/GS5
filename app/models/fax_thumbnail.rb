class FaxThumbnail < ActiveRecord::Base
  mount_uploader :thumbnail, ThumbnailUploader
  validates_presence_of :thumbnail
  
  belongs_to :fax_document
  
  acts_as_list :scope => :fax_document
end
