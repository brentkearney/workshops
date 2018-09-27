# Copyright (c) 2018 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

require 'rails_helper'

RSpec.describe Griddler::AuthenticationController, type: :controller do

  def incoming_email
    {
      "_json" => [{
        "msys" => {
          "relay_message" => {
            "rcpt_to" => "to_email@example.com", "friendly_from" => "from_email@example.net", "customer_id" => "69", "content" => {
              "text" => "Just a test email.\r\n", "subject" => "testing", "html" => "<div dir=\"ltr\">Just a test email.<div><br></div></div>\r\n", "headers" => [{
                "Return-Path" => "<from_email@example.net>"
              }, {
                "MIME-Version" => "1.0"
              }, {
                "From" => "Testuser <from_email@example.net>"
              }, {
                "Date" => "Tue, 25 Sep 2018 16:17:17 -0600"
              }, {
                "Message-ID" => "<CAGiXaEY4EFwNFHexqN7Tn@mail.example.net>"
              }, {
                "Subject" => "testing"
              }, {
                "To" => "to_email@example.com"
              }, {
                "Content-Type" => "multipart/alternative; boundary=\"0000000000009d29da0576b9780f\""
              }], "email_rfc822" => "Return-Path: <from_email@example.net>\r\nMIME-Version: 1.0\r\nFrom: Testuser <from_email@example.net>\r\nDate: Tue, 25 Sep 2018 16:17:17 -0600\r\nMessage-ID: <CAGiXaEY4EFwNFHexqN7Tn@mail.example.net>\r\nSubject: testing\r\nTo: to_email@example.com\r\nContent-Type: multipart/alternative; boundary=\"0000000000009d29da0576b9780f\"\r\n\r\n--0000000000009d29da0576b9780f\r\nContent-Type: text/plain; charset=\"UTF-8\"\r\n\r\nJust a test email.\r\n--0000000000009d29da0576b9780f\r\nContent-Type: text/html; charset=\"UTF-8\"\r\n\r\n<div dir=\"ltr\">Just a test email.\r\n--0000000000009d29da0576b9780f--\r\n", "email_rfc822_is_base64" => false, "to" => ["to_email@example.com"]
              }, "msg_from" => "from_email@example.net", "webhook_id" => "1234", "protocol" => "smtp"
            }
          }
        }
    ]}
  end

  describe '#incoming' do
    context 'GET' do
      it 'responds with unauthorized' do
        get :incoming

        expect(response).to be_unauthorized
      end
    end

    context 'POST without auth token' do
      it 'responds with unauthorized' do
        post :incoming, incoming_email

        expect(response).to be_unauthorized
      end
    end

    context 'POST with invalid auth token' do
      it 'responds with unauthorized' do
        request.env["X-MessageSystems-Webhook-Token"] = 'foo'
        post :incoming, incoming_email

        expect(response).to be_unauthorized
      end
    end

    context 'POST with valid auth token' do
      it 'responds with success' do
        valid_token = GetSetting.site_setting('SPARKPOST_AUTH_TOKEN')
        expect(valid_token).not_to be_empty
        @request.headers["X-MessageSystems-Webhook-Token"] = valid_token

        post :incoming, incoming_email

        expect(response).to be_success
      end
    end

    context 'POST with valid token but invalid email format' do
      it 'responds with bad request' do
        valid_token = GetSetting.site_setting('SPARKPOST_AUTH_TOKEN')
        expect(valid_token).not_to be_empty
        @request.headers["X-MessageSystems-Webhook-Token"] = valid_token

        post :incoming, { email: 'Here is my message!' }

        expect(response).to be_a_bad_request
      end
    end
  end
end
