class FaxDocument < ActiveRecord::Base
#  attr_accessible :inbound, :transmission_time, :sent_at, :document_total_pages, :document_transferred_pages, :ecm_requested, :ecm_used, :image_resolution, :image_size, :local_station_id, :result_code, :result_text, :remote_station_id, :success, :transfer_rate, :t38_gateway_format, :t38_peer, :document

  mount_uploader :document, DocumentUploader
  mount_uploader :tiff, TiffUploader

  validates_presence_of :document
  validates_numericality_of :retry_counter, :only_integer => true, :greater_than_or_equal_to => 0

  belongs_to :fax_account
  belongs_to :fax_resolution
  
  validates_presence_of :fax_resolution_id
  validates_presence_of :fax_resolution
  
  has_one :destination_phone_number, :class_name => 'PhoneNumber', :as => :phone_numberable, :dependent => :destroy
  accepts_nested_attributes_for :destination_phone_number

  has_many :fax_thumbnails, :order => :position, :dependent => :destroy

  after_create :render_thumbnails
  after_create :convert_pdf_to_tiff
  
  # Scopes
  scope :inbound, where(:state => 'inbound')
  scope :outbound, where(:state => ['queued_for_sending','sending','successful','unsuccessful'])

  # State Machine stuff
  state_machine :initial => :new do
    event :queue_for_sending do
      transition [:new] => :queued_for_sending
    end
    
    event :send_now do
      transition [:queued_for_sending] => :sending
    end
    
    event :cancel do
      transition [:sending, :queued_for_sending] => :unsuccessful
    end
    
    event :successful_sent do
      transition [:sending, :queued_for_sending] => :successful
    end
    
    event :mark_as_inbound do
      transition [:new] => :inbound
    end  
  end
  
  def to_s
    name
  end
  
  private
  def render_thumbnails
    directory = "/tmp/GS-#{GEMEINSCHAFT_VERSION}/fax_thumbnails/#{self.id}"
    system('mkdir -p ' + directory)
    system("cd #{directory} && convert #{Rails.root.to_s}/public#{self.document.to_s}[0-100] -colorspace Gray PNG:'fax_page.png'")
    number_of_thumbnails = Dir["#{directory}/fax_page-*.png"].count
    (0..(number_of_thumbnails-1)).each do |i|
      fax_thumbnail = self.fax_thumbnails.build
      fax_thumbnail.thumbnail = File.open("#{directory}/fax_page-#{i}.png")
      fax_thumbnail.save!
    end
    system("rm -rf #{directory}")
    self.update_attributes(:document_total_pages => number_of_thumbnails) if self.document_total_pages.nil?
  end
  
  def convert_pdf_to_tiff
    page_size_a4 = '595 842'
    page_size_command = "<< /Policies << /PageSize 3 >> /InputAttributes currentpagedevice /InputAttributes get dup { pop 1 index exch undef } forall dup 0 << /PageSize [ #{page_size_a4} ] >> put >> setpagedevice"
    directory = "/tmp/GS-#{GEMEINSCHAFT_VERSION}/faxes/#{self.id}"
    system('mkdir -p ' + directory)
    tiff_file_name = File.basename(self.document.to_s.downcase, ".pdf") + '.tiff'
    system "cd #{directory} && gs -q -r#{self.fax_resolution.resolution_value} -dNOPAUSE -dBATCH -dSAFER -sDEVICE=tiffg3 -sOutputFile=\"#{tiff_file_name}\" -c \"#{page_size_command}\" -- \"#{Rails.root.to_s}/public#{self.document.to_s}\""
    self.tiff = File.open("#{directory}/#{tiff_file_name}")
    self.save
    system("rm -rf #{directory}")
  end

end
