class FaxDocument < ActiveRecord::Base
#  attr_accessible :inbound, :transmission_time, :sent_at, :document_total_pages, :document_transferred_pages, :ecm_requested, :ecm_used, :image_resolution, :image_size, :local_station_id, :result_code, :result_text, :remote_station_id, :success, :transfer_rate, :t38_gateway_format, :t38_peer, :document

  mount_uploader :document, FaxDocumentUploader

  validates_presence_of :document
  validates_numericality_of :retry_counter, :only_integer => true, :greater_than_or_equal_to => 0

  belongs_to :fax_account
  belongs_to :fax_resolution
  
  validates_presence_of :fax_resolution_id
  validates_presence_of :fax_resolution
  
  has_one :destination_phone_number, :class_name => 'PhoneNumber', :as => :phone_numberable, :dependent => :destroy
  accepts_nested_attributes_for :destination_phone_number

  has_many :fax_thumbnails, :order => :position, :dependent => :destroy

  after_save :convert_to_tiff
  after_create :render_thumbnails
  
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
    "#{self.remote_station_id}-#{self.created_at}-#{self.id}".gsub(/[^a-zA-Z0-9]/,'')
  end

  def render_thumbnails
    self.delay.create_thumbnails_and_save_them
  end
  
  def create_thumbnails_and_save_them
    tmp_dir = "/var/spool/gemeinschaft/fax_convertions/#{self.id}"
    FileUtils.mkdir_p tmp_dir
    system("cd #{tmp_dir} && convert #{self.document.path} -colorspace Gray PNG:'fax_page.png'")
    Dir.glob("#{tmp_dir}/fax_page*.png").each do |thumbnail|
      fax_thumbnail = self.fax_thumbnails.build
      fax_thumbnail.thumbnail = File.open(thumbnail)
      fax_thumbnail.save
    end
    FileUtils.rm_rf tmp_dir
  end

  def tiff_to_pdf
    if !File.exists?(self.tiff)
      return nil
    end

    working_path, file_name = File.split(self.tiff)
    pdf_file = "#{working_path}/#{File.basename(self.tiff, '.tiff')}.pdf"

    system "tiff2pdf \\
      -o \"#{pdf_file}\" \\
      -p letter \\
      -a \"#{self.remote_station_id}\" \\
      -c \"AMOOMA Gemeinschaft version #{GsParameter.get('GEMEINSCHAFT_VERSION')}\" \\
      -t \"#{self.remote_station_id}\" \"#{self.tiff}\""

    if !File.exists?(pdf_file)
      return nil
    end

    return pdf_file
  end

  def to_tiff
    page_size_a4 = '595 842'
    page_size_command = "<< /Policies << /PageSize 3 >> /InputAttributes currentpagedevice /InputAttributes get dup { pop 1 index exch undef } forall dup 0 << /PageSize [ #{page_size_a4} ] >> put >> setpagedevice"
    working_path, file_name = File.split(self.document.to_s)
    tiff_file = File.basename(file_name.to_s.downcase, File.extname(file_name)) + '.tiff'
    result = system "cd #{store_dir} && gs -q -r#{self.fax_resolution.resolution_value} -dNOPAUSE -dBATCH -dSAFER -sDEVICE=tiffg3 -sOutputFile=\"#{tiff_file}\" -c \"#{page_size_command}\" -- \"#{self.document.to_s}\""
    
    if !File.exists?("#{store_dir}/#{tiff_file}")
      return nil
    end

    return "#{store_dir}/#{tiff_file}"
  end

  def store_dir
    if self.try(:inbound)
      "/var/opt/gemeinschaft/fax/in/#{self.id}"
    else
      "/var/opt/gemeinschaft/fax/out/#{self.id}"
    end
  end

  private
  def convert_to_tiff
    if self.tiff.blank?
      self.tiff = self.to_tiff
      if self.tiff
        return self.save
      end
    end
  end

end
