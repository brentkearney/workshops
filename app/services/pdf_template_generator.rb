class PdfTemplateGenerator
  attr_reader :location, :template

  def initialize(location, template)
    @location = location
    @template = template
  end

  def pdf_file
    @page_title = "#{location} Invitation Details"

    pdf_file = WickedPdf.new.pdf_from_string(
      template,
      encoding: 'UTF-8',
      lowquality: false,
      page_size: 'Letter'
    )

    # save to a file (for testing)
    if ENV['SAVE_PDF_ATTACHMENTS']
      save_path = Rails.root.join('tmp','invitation.pdf')
      File.open(save_path, 'wb') do |file|
        file << pdf_file
      end
    end

    pdf_file
  end
end
