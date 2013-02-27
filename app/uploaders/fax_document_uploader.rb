# encoding: utf-8

class FaxDocumentUploader < CarrierWave::Uploader::Base
  include CarrierWave::MiniMagick
 
  storage :file
 
  def store_dir
    model.store_dir
  end

  def cache_dir
    '/tmp/gs_fax_uploader'
  end

  def extension_white_list
    %w(pdf ps jpg jpeg gif png tif tiff)
  end
end
