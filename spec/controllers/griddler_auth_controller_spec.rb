# Copyright (c) 2018 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

require 'rails_helper'

RSpec.describe Griddler::AuthenticationController, type: :controller do

  def incoming_email
=begin  message format from Sparkpost:
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

    Message from Mailgun:
=end
    {
      "recipient"=>"to_email@example.com",
      "sender"=>"from_email@example.net",
      "subject"=>"Testing",
      "from"=>"From Person <from_email@example.net>",
      "X-Mailgun-Incoming"=>"Yes",
      "X-Envelope-From"=>"<from_email@example.net>",
      "Received"=>"by mailfront22.runbox with esmtpsa  [Authenticated alias (682413)]  (TLS1.2:ECDHE_RSA_AES_256_GCM_SHA384:256)\t(Exim 4.90_1)\tid 1iHyxr-00068v-BJ\tfor to_email@example.com; Wed, 09 Oct 2019 01:32:23 +0200",
      "From"=>"From Person <from_email@example.net>",
      "Content-Type"=>"text/plain; charset=\"us-ascii\"",
      "Content-Transfer-Encoding"=>"7bit",
      "Mime-Version"=>"1.0 (Mac OS X Mail 12.4 \\(3445.104.11\\))",
      "Subject"=>"Testing",
      "Message-Id"=>"<9216EE88-3E5F-42FD-A91D-67878145B947@kearneys.ca>",
      "Date"=>"Tue, 8 Oct 2019 17:32:20 -0600",
      "To"=>"to_email@example.com",
      "X-Mailer"=>"Apple Mail (2.3445.104.11)",
      'X-WS-Mailer'=>"{'sender'=>'From Person','event' =>'19w5055'}",
      "message-headers"=>"[[\"X-Mailgun-Incoming\", \"Yes\"], [\"X-Envelope-From\", \"<from_email@example.net>\"], [\"Received\", \"from aibo.runbox.com (aibo.runbox.com [91.220.196.211]) by mxa.mailgun.org with ESMTP id 5d9d1c8e.7f3a14c55538-smtp-in-n02; Tue, 08 Oct 2019 23:32:30 -0000 (UTC)\"], [\"Received\", \"from [10.9.9.204] (helo=mailfront22.runbox)\\tby mailtransmit03.runbox with esmtp (Exim 4.86_2)\\t(envelope-from <from_email@example.net>)\\tid 1iHyxw-0001J1-4C\\tfor to_email@example.com; Wed, 09 Oct 2019 01:32:28 +0200\"], [\"Received\", \"by mailfront22.runbox with esmtpsa  [Authenticated alias (682413)]  (TLS1.2:ECDHE_RSA_AES_256_GCM_SHA384:256)\\t(Exim 4.90_1)\\tid 1iHyxr-00068v-BJ\\tfor to_email@example.com; Wed, 09 Oct 2019 01:32:23 +0200\"], [\"From\", \"From Person <from_email@example.net>\"], [\"Content-Type\", \"text/plain; charset=\\\"us-ascii\\\"\"], [\"Content-Transfer-Encoding\", \"7bit\"], [\"Mime-Version\", \"1.0 (Mac OS X Mail 12.4 \\\\(3445.104.11\\\\))\"], [\"Subject\", \"Testing\"], [\"Message-Id\", \"<9216EE88-3E5F-42FD-A91D-67878145B947@kearneys.ca>\"], [\"Date\", \"Tue, 8 Oct 2019 17:32:20 -0600\"], [\"To\", \"to_email@example.com\"], [\"X-Mailer\", \"Apple Mail (2.3445.104.11)\"]]",
      "timestamp"=>"1570577551",
      "token"=>"48880e0c50419237cd238322bc8f9a6a16f3d0d59efe608bda",
      "signature"=>"b20a0cbe1395a770ad2f22fe9fd3cc1c234461f647f8e469479dfb472af706aa",
      "body-plain"=>"Just testing",
      "stripped-text"=>"Just testing",
      "stripped-html"=>"<p>Just testing</p>"
    }
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
        mail = incoming_email.dup
        mail.delete('token')
        post :incoming, params: mail

        expect(response).to be_unauthorized
      end
    end

    context 'POST with invalid auth token' do
      it 'responds with unauthorized' do
        mail = incoming_email.dup
        mail['token'] = 'foo'
        post :incoming, params: mail

        expect(response).to be_unauthorized
      end
    end

    context 'POST with valid auth token' do
      it 'responds with success' do
        post :incoming, params: incoming_email

        expect(response).to be_successful
      end
    end

    context 'POST with valid token but invalid post format' do
      it 'responds with bad request' do
        mail = incoming_email.dup
        mail.delete("X-Mailgun-Incoming")

        post :incoming, params: mail

        expect(response).to be_a_bad_request
      end
    end
  end

  describe '#bounce' do
    let(:bounce_params) do
      {
        "signature"=>{"timestamp"=>"1570577551", "token"=>"48880e0c50419237cd238322bc8f9a6a16f3d0d59efe608bda", "signature"=>"b20a0cbe1395a770ad2f22fe9fd3cc1c234461f647f8e469479dfb472af706aa"},
        'event-data' => {
          'severity' => 'permanent',
          'message' => {
            'headers' => {
              'from' => incoming_email['sender'],
              'to' => incoming_email['recipient'],
              'subject' => incoming_email['subject'],
            }
          },
          'recipient' => incoming_email['recipient'],
          'timestamp' => 1571198580,
          'delivery-status' => {
            'code' => 550,
            'description' => 'Unable to deliver',
            'message' => 'Recipient not found'
          }
        }
      }
    end

    context 'GET' do
      it 'responds with unauthorized' do
        get :bounces

        expect(response).to be_unauthorized
      end
    end

    context 'POST without auth token' do
      it 'responds with unauthorized' do
        post_params = bounce_params.merge({'signature'=>{'token'=>''}})

        post :bounces, params: post_params

        expect(response).to be_unauthorized
      end
    end

    context 'POST with invalid auth token' do
      it 'responds with unauthorized' do
        post_params = bounce_params.merge({'signature'=>{'token'=>'foo'}})

        post :bounces, params: post_params

        expect(response).to be_unauthorized
      end
    end

    context 'POST with valid auth token' do
      it 'responds with success' do
        post :bounces, params: bounce_params

        expect(response).to be_successful
      end
    end

    context 'POST with valid token but invalid post format' do
      it 'responds with bad request' do
        post_params = bounce_params.merge({'event-data'=>{'severity'=>'none'}})

        post :bounces, params: post_params

        expect(response).to be_a_bad_request
      end
    end
  end
end
