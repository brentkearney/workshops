# Copyright (c) 2018 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

# Receives Griddler:Email object from EventMaillist, returns formatted parts
class EmailParser
  attr_accessor :text_body, :html_body, :inline_attachments

  def initialize(email, list_name)
    @email = email
    @list_name = list_name
  end

  def parse
    {
      text_body: prepare_text(@email.raw_text),
      html_body: prepare_html(@email.raw_html),
      inline_attachments: prepare_inline(@email.send(:params))
    }
  end

  def prepare_text(text_body)
    prelude = "From #{@email.from[:full]} to #{@list_name} on #{@email.headers['Date']}:"
    prelude << "\n" + '-' * 70 + "\n\n"

    if text_body.blank?
      @text_body = prelude
    else
      @text_body = prelude + text_body
    end
    @text_body
  end

  def prepare_html(html_body)
    unless html_body.blank?
      prelude = "<p>From #{@email.from[:full]} to #{@list_name} on #{@email.headers['Date']}:</p>\n"
      prelude << "<hr width=\"100%\" />\n\n"

      if html_body.include?('<body')
        p = html_body.split('<body')
        before_body = p[0]
        inside_body = p[1].split('>')[0]
        after_body = p[1]
        after_body.slice!("#{inside_body}>")
        @html_body = before_body + '<body' + inside_body + '>' + prelude + after_body
      else
        @html_body = "<html><body>" + prelude + html_body + "\n</body></html>"
      end
    end
    @html_body
  end

  # Get filename:content-id mapping of inline attachments
  def prepare_inline(params)
    @inline_attachments = {}
    return @inline_attachments if params['_json'].blank?
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
