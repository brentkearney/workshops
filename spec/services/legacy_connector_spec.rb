# Copyright (c) 2016 Banff International Research Station
#
# Permission is hereby granted, free of charge, to any person obtaining a copy of this
# software and associated documentation files (the "Software"), to deal in the Software
# without restriction, including without limitation the rights to use, copy, modify,
# merge, publish, distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to the following
# conditions:
#
# The above copyright notice and this permission notice shall be included in all copies
# or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
# INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
# PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
# HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF
# CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE
# OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

require 'rails_helper'

describe "LegacyConnector", :type => :feature do
  before do
    @lc = LegacyConnector.new
  end

  context '#list_events' do
    it 'given invalid year, returns an error' do
      event_list = @lc.list_events('fake', 'years')

      expect(event_list).to contain_exactly(["error", "Invalid years."])
    end

    it 'given two years, it returns a list of valid event_ids' do
      event_list = @lc.list_events('2014', '2015')
      expect(event_list).not_to be_empty

      event_list.each do |event_id|
        expect(event_id).to match /#{Global.event.code_pattern}/
      end
    end

    it 'handles backwards input' do
      # Handles backwards input
      event_list = @lc.list_events('2015', '2014')

      expect(event_list).not_to be_empty
    end

    it 'accepts months as YYYYMM' do
      event_list = @lc.list_events('201502', '201503')

      expect(event_list).not_to be_empty
      expect(event_list.first).to match /#{Global.event.code_pattern}/
    end
  end

  context '#get_event_data' do
    it 'retrieves data for a given event code' do
      event = @lc.get_event_data('15w5080')
      expect(event).not_to be_empty

      expect(event).to include("code" => "15w5080")
      expect(event).to include('name' => "New Perspectives for Relational Learning")
      expect(event).to include('start_date')
      expect(event).to include('end_date')
      expect(event).to include('event_type')
      expect(event).to include('max_participants')
      expect(event).to include('description')
    end
  end

  context '#get_event_data_for_year' do
    it 'retrieves data for given year' do
      event_data = @lc.get_event_data_for_year('2014')

      expect(event_data).not_to be_empty
      expect(event_data.last['code']).to match /#{Global.event.code_pattern}/
    end
  end

  context '#get_members' do
    it 'retrieves membership data for a given event' do
      event = create(:event, code: '15w5080')
      members = @lc.get_members(event)
      expect(members).not_to be_empty

      members.each do |member|
        expect(member).to include('Workshop')
        expect(member).to include('Membership')
        expect(member).to include('Person')
        expect(member["Person"]["email"]).to match /\w+@\w+\.\w+/
      end
    end
  end

  context '#get_person' do
    it 'retrieves person data for a given legacy_id' do
      person = @lc.get_person('13167')

      expect(person["lastname"]).to eq('Tester')
    end
  end

  context '#search_person' do
    it 'retrieves person data for a given email address' do
      person = @lc.search_person('test@test.birs.ca')

      expect(person["lastname"]).to eq('Tester')
    end
  end

  ## This works, but we don't want to create new Person records with each run of rspec
  context '#add_person' do
    it "can create new person records" do
      # remote_person = @lc.search_person('test2@test2.birs.ca')
      # expect(remote_person).to be_empty

      # person = Person.new(person_attributes(firstname: "Another", lastname: "TestUser", email: "test2@test.birs.ca", updated_by: 'RSpec tests'))
      #
      # legacy_id = @lc.add_person(person)
      # expect(legacy_id).not_to be_empty
      # puts "Legacy_id returned: #{legacy_id}"
      #
      # remote_person = @lc.get_person(legacy_id)
      # expect(remote_person).not_to be_empty
      # expect(remote_person["lastname"]).to eq("TestUser")
    end
  end

  context '#add_member' do

  end

  context '#add_members' do

  end

  context '#update_member' do

  end

  context '#update_members' do

  end

  context '#get_lectures' do
    it 'can retrieve Lectures for given event' do
      lectures = @lc.get_lectures('15w5013')

      expect(lectures).not_to be_empty
      lectures.each do |lecture|
        expect(lecture['event_id']).to eq('15w5013')
      end
    end
  end

  context '#get_legacy_lecture' do
    it 'can retrieve a Lecture given legacy_id' do
      lectures = @lc.get_lectures('15w5013')
      legacy_id = lectures.last['legacy_id']
      title = lectures.last['title']
      expect(legacy_id.to_i).to be > 0
      expect(title).not_to be_empty

      the_lecture = @lc.get_legacy_lecture(legacy_id)

      expect(the_lecture['title']).to eq(title)
    end
  end

  context '#add_lecture' do
    it 'adds a Lecture record to the remote database' do
      event = build(:event, code: '14w6661', start_date: '2003-01-05', end_date: '2003-01-10')
      person = build(:person, legacy_id: '13167')
      lecture = create(:lecture, event: event, person: person, title: 'RSpec Test LegacyConnector#add_lecture',
                       start_time: (event.start_date + 1.days).to_time.change({ hour: 9, min: 0}),
                       end_time: (event.start_date + 1.days).to_time.change({ hour: 10, min: 0}))

      lecture_id = @lc.add_lecture(lecture)

      expect(lecture_id).not_to be_nil
      expect(lecture_id.to_i).to be > 0
      the_lecture = @lc.get_legacy_lecture(lecture_id)
      expect(the_lecture['title']).to eq(lecture.title)
    end
  end

  context '#delete_lecture' do
    it 'deletes a lecture from the remote database' do
      # I know, this depends on the last test, but in the interest of decreasing database pollution...
      lecture = @lc.get_lectures('14w6661').last
      expect(lecture).not_to be_nil
      expect(lecture['title']).to eq('RSpec Test LegacyConnector#add_lecture')

      # This works, but if we leave it in the db, the previous test won't create a new one every run
      # lecture_id = lecture['legacy_id']
      # @lc.delete_lecture(lecture_id)

      # remote_lecture = @lc.get_legacy_lecture(lecture_id)
      # expect(remote_lecture).to be_empty
    end
  end

end