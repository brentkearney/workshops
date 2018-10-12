# Copyright (c) 2018 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

# Receives Griddler:Email object from EventMaillist, returns formatted parts
class EmailParser
  attr_accessor :text_body, :html_body, :inline_attachments

  def initialize(email, event_code)
    @email = email
    @event_code = event_code
  end

  def parse
    {
      text_body: prepare_text(@email.raw_text),
      html_body: prepare_html(@email.raw_html),
      inline_attachments: prepare_inline(@email.send(:params))
    }
  end

  def prepare_text(text_body)
    unless text_body.blank?
      @first_word = text_body.match(/\A.+\b/)
      prelude = '-' * 70 + "\n"
      prelude << "Message from #{@email.from[:full]} to the #{@event_code} workshop on #{@email.headers['Date']}:"
      prelude << "\n" + '-' * 70 + "\n\n"
      @text_body = prelude + text_body
    end
    @text_body
  end

  def prepare_html(html_body)
    unless html_body.blank?
      prelude = "<hr width=\"100%\" />\n"
      prelude << "<p>Message from #{@email.from[:full]} to the #{@event_code} workshop on #{@email.headers['Date']}:</p>\n"
      prelude << "<hr width=\"100%\" />\n\n"
      @html_body = html_body.gsub(/<body(.+)">#{@first_word}/, "<body\\1\">#{prelude}#{@first_word}")
    end
    @html_body
  end

  # Get filename:content-id mapping of inline attachments
  def prepare_inline(params)
    @inline_attachments = {}
    return @inline_attachments if params['_json'].nil?
    raw_email = params['_json'][0]['msys']['relay_message']['content']['email_rfc822']
    if raw_email =~ /Content-Disposition: inline/
      filename = ''
      content_id = ''
      capture = false
      raw_email.each_line do |line|
        capture = true if line =~ /Content-Disposition: inline/i
        if capture
          filename = line.split('=').last.strip if line =~ /filename/i
          content_id = line.split(':').last.tr('<>', '').strip if line =~ /Content-Id/i
        end
        if !filename.empty? && !content_id.empty?
          @inline_attachments[filename] = content_id
          filename = ''
          content_id = ''
          capture = false
        end
      end
    end
    @inline_attachments
  end
end
