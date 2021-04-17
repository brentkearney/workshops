# Copyright (c) 2018 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

require 'rails_helper'

# EmailTemplateSelector should return the correct email template name
# for each workshop type, membership attendance status, and membership role
describe 'InvitationTemplateSelector' do
  GetSetting.site_setting('event_formats').each do |event_format|
    context "For #{event_format} events" do
      GetSetting.site_setting('event_types').each do |event_type|
        context "Of type #{event_type}" do
          let(:event) { build(:event, event_type:   event_type,
                                      event_format: event_format) }

          Membership::ATTENDANCE.each do |attendance|
            context "For membership attendance '#{attendance}'" do
              let(:membership) { build(:membership, event: event) }

              it "returns a template for #{event_format}
                #{event_type}-#{attendance}".squish do

                template_name = event_format + '-' + event_type + '-' + attendance

                templates = InvitationTemplateSelector.new(membership, attendance)
                                                      .set_template

                expect(templates[:template_name]).to eq(template_name)
              end
            end # context ... attendance
          end # attendances.each
        end # context ... event_type
      end # event_types.each
    end # context ... event_format
  end # event_formats.each
end
