# encoding: utf-8

class GenericFileUploader < CarrierWave::Uploader::Base
 
  storage :file
 
  def store_dir
    model.store_dir
  end

  def cache_dir
    '/tmp/generic_file_uploader'
  end

  def extension_white_list
    %w(pdf ps jpg jpeg gif png tif tiff wav mp3)
  end
end
