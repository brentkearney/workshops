# Copyright (c) 2018 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

require 'rails_helper'

describe 'EmailParser' do
  let(:params) do
  {
    to: ['event_code@example.com'],
    from: 'Webmaster <webmaster@example.net>',
    subject: 'Testing email processing',
    text: 'A Test Message.',
    html: '<html><body><p>A Test Message.</p></body></html>',
    Date: "Tue, 25 Sep 2018 16:17:17 -0600"
  }
  end

  before do
    @from_person = create(:person, email: 'webmaster@example.net',
                                   firstname: 'Webmaster')
    @ep = EmailParser.new(subject, '18w6660@example.com')
  end

  let(:prelude) { "From #{@from_person.name} to 18w6660@example.com" }

  subject { Griddler::Email.new(params) }

  it 'accepts a Griddler::Email object' do
    expect(@ep.class).to eq(EmailParser)
  end

  it '.parse returns a hash' do
    expect(@ep.parse).to be_a(Hash)
  end

  it 'has .text_body, .html_body, .inline_attachments attributes' do
    @ep.parse
    expect(@ep.text_body).not_to be_nil
    expect(@ep.html_body).not_to be_nil
    expect(@ep.inline_attachments).not_to be_nil
  end

  it ':text_body returns the text portion of the email with a prelude' do
    text_body = @ep.parse[:text_body]
    expect(text_body).to include(params[:text])
    expect(text_body).to include(prelude)
  end

  it 'empty text_body returns just the prelude' do
    new_params = params
    new_params[:text] = ''
    ep = EmailParser.new(Griddler::Email.new(new_params), '18w6660@example.com')
    text_body = ep.parse[:text_body]
    expect(text_body).to include(prelude)
  end

  it ':html_body returns the html portion of the email with a prelude' do
    html_body = @ep.parse[:html_body]
    expect(html_body).to include('A Test Message.')
    expect(html_body).to include(prelude)
  end

  it 'handles html with no <body> tags' do
    np = params
    np[:html] = '<div dir=\"ltr\">Just a test<div><br></div></div>'
    email = Griddler::Email.new(np)
    ep = EmailParser.new(email, '18w6660@example.com')
    html_body = ep.parse[:html_body]

    expect(html_body).to include('Just a test')
    expect(html_body).to include(prelude)
  end
end
