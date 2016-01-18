# Copyright (c) 2016 Brent Kearney
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
  describe "From Legacy DB, it can:" do  
    before do
      @lc = LegacyConnector.new
    end

    it 'get_event_data: retrieves data for a specific event' do    
      event = @lc.get_event_data('15w5080')
      expect(event['name']).to eq("New Perspectives for Relational Learning")
    end
    
    it "list_events: get a list of events between years or months" do
      event_list = @lc.list_events('fake', 'years')
      expect(event_list).to contain_exactly(["error", "Invalid years."])
    
      event_list = @lc.list_events('2014', '2015')
      expect(event_list).not_to be_empty
      event_list.each do |event_id|
        expect(event_id).to match /^\d{2}\D+\d{3,4}$/
      end

      # Handles backwards input
      event_list = @lc.list_events('2015', '2014')
      expect(event_list).not_to be_empty
      
      event_list = @lc.list_events('201502', '201503')
      expect(event_list).not_to be_empty
      expect(event_list.count).to be > 3
      expect(event_list.count).to be < 12
    end
    
    it "download event data" do
      event_data = @lc.get_event_data('14w5075')
      expect(event_data).not_to be_empty
      expect(event_data).to include('code' => '14w5075')
      expect(event_data).to include('name')
      expect(event_data).to include('start_date')
      expect(event_data).to include('end_date')
      expect(event_data).to include('event_type')
      expect(event_data).to include('max_participants')
      expect(event_data).to include('description')        
    end
    
    it "download all event data in a given year" do
      event_list = @lc.list_events('2014', '2014')
      event_data = @lc.get_event_data_for_year('2014')
      expect(event_data).not_to be_empty
    
      event_list.each do |event_id|
        search = event_data.detect {|event| event['code'] == event_id }
        expect(search).to include('code' => event_id)
        expect(search).to include('name')
        expect(search).to include('description')
      end
    end

    it "get membership data for a specific event" do
      members = @lc.get_members('14w5075')
      expect(members).not_to be_empty
      
      members.each do |member| 
        expect(member).to include('Workshop')
        expect(member).to include('Membership')
        expect(member).to include('Person')
        expect(member["Person"]["email"]).to match /\w+@\w+\.\w+/
      end
    end
    
    it "get data for a specific person by legacy_id" do
      person = @lc.get_person('7946')
      expect(person["lastname"]).to eq('Kearney')
    end
    
    it "get data for a specific person by email" do
      person = @lc.search_person('brentk@birs.ca')
      expect(person["lastname"]).to eq('Kearney')
    end
    
    it "can create new person records" do
      ## This works, but we don't want to create new Person records with each run of rspec
      # remote_person = @lc.search_person('test2@test.birs.ca')
      #       expect(remote_person).to be_empty
      #       
      #       person = Person.new(person_attributes(firstname: "Another", lastname: "TestUser", email: "test2@test.birs.ca", updated_by: 'RSpec tests'))
      #       
      #       legacy_id = @lc.add_person(person)
      #       expect(legacy_id).not_to be_empty
      #       puts "Legacy_id returned: #{legacy_id}"
      #            
      #       remote_person = @lc.get_person(legacy_id)
      #       expect(remote_person).not_to be_empty
      #       expect(remote_person["lastname"]).to eq("TestUser")
    end

    it 'can retrieve Lectures for an event' do
      lectures = @lc.get_lectures('15w5013')
      expect(lectures).not_to be_nil
      lectures.each do |lecture|
        expect(lecture['event_id']).to eq('15w5013')
      end
    end

    it 'can retrieve an individual Lecture based on legacy_id' do
      legacy_id = 0
      title = 'foo'

      lectures = @lc.get_lectures('15w5013')
      expect(lectures).not_to be_nil
      lectures.each do |lecture|
        legacy_id = lecture['legacy_id']
        title = lecture['title']
      end
      expect(legacy_id.to_i).to be > 0
      expect(title).not_to eq('foo')

      the_lecture = @lc.get_legacy_lecture(legacy_id)
      expect(the_lecture['title']).to eq(title)
    end

    it 'can add a lecture to the remote db' do
      event = FactoryGirl.build(:event, code: '14w6661', start_date: '2003-01-05', end_date: '2003-01-10')
      person = FactoryGirl.create(:person, legacy_id: '7946')
      lecture = FactoryGirl.create(:lecture, event: event, person: person,
                                    start_time: (event.start_date + 1.days).to_time.change({ hour: 9, min: 0}),
                                    end_time: (event.start_date + 1.days).to_time.change({ hour: 10, min: 0}))

      # add_lecture() updates existing lectures, so this doesn't add a new one every run
      lecture_id = @lc.add_lecture(lecture)
      expect(lecture_id).not_to be_nil
      expect(lecture_id.to_i).to be > 0
      the_lecture = @lc.get_legacy_lecture(lecture_id)
      expect(the_lecture['title']).to eq(lecture.title)
      @lc.delete_lecture(lecture_id) # clean up db
    end

    # the after_save callback is disabled in test mode
    # it 'adding a lecture gets the (new) remote lecture\'s primary id and adds it to the legacy_id field of the local record' do
    #   event = FactoryGirl.build(:event, code: '14w6661')
    #   person = FactoryGirl.create(:person, legacy_id: '7946')
    #   lecture = FactoryGirl.create(:lecture, event: event, person: person,
    #                                start_time: (event.start_date + 1.days).to_time.change({ hour: 9, min: 0}),
    #                                end_time: (event.start_date + 1.days).to_time.change({ hour: 10, min: 0}))
    #
    #   # add_lecture() updates existing lectures, so this doesn't add a new one every run
    #   remote_id = @lc.add_lecture(lecture)
    #   expect(remote_id).not_to be_nil
    #
    #   updated_lecture = Lecture.find(lecture.id)
    #   expect(lecture.legacy_id).to eq(remote_id)
    # end

    it 'can remove a lecture from the remote db' do
      event = FactoryGirl.build(:event, code: '14w6661', start_date: '2003-01-05', end_date: '2003-01-10')
      person = FactoryGirl.create(:person, legacy_id: '7946')
      lecture = FactoryGirl.create(:lecture, event: event, person: person, title: '123456789 Yeah',
                                   start_time: (event.start_date + 1.days).to_time.change({ hour: 9, min: 0}),
                                   end_time: (event.start_date + 1.days).to_time.change({ hour: 10, min: 0}))
      lecture_id = @lc.add_lecture(lecture)

      remote_lecture = @lc.get_legacy_lecture(lecture_id)
      expect(remote_lecture['title']).to eq('123456789 Yeah')

      @lc.delete_lecture(lecture_id)
      remote_lecture = @lc.get_legacy_lecture(lecture_id)
      expect(remote_lecture).to be_empty
    end

  end
end