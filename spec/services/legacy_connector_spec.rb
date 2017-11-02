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

describe "LegacyConnector", type: :feature do
  before do
    Event.destroy_all
    @lc = LegacyConnector.new
  end

  let(:event1) { build(:event) }
  let(:event2) { build(:event) }
  let(:person) { build(:person, legacy_id: 1) }
  let(:person2) { build(:person) }
  let(:membership1) { build(:membership, person: person, event: event1) }
  let(:membership2) { build(:membership, person: person2, event: event2) }

  def stub_rest_client(method, data)
    allow(RestClient).to receive(method).and_return(data.to_json)
  end

  context '#list_events' do
    before do
      stub_rest_client(:get, [event1.code, event2.code])
    end

    it 'given invalid year, returns an error' do
      stub_rest_client(:get, ['error', 'Invalid years.'])

      event_list = @lc.list_events('fake', 'years')

      expect(event_list).to include('error', 'Invalid years.')
    end

    it 'given two years, it returns a list of valid event_ids' do
      event_list = @lc.list_events('2014', '2015')

      expect(event_list).to be_an_instance_of(Array)
      event_list.each do |event_id|
        expect(event_id).to match /#{Setting.Site['code_pattern']}/
      end
    end

    it 'handles backwards input' do
      event_list = @lc.list_events('2015', '2014')

      expect(event_list).to be_an_instance_of(Array)
      expect(event_list).to include(event1.code, event2.code)
    end

    it 'accepts months as YYYYMM' do
      event_list = @lc.list_events('201502', '201503')

      expect(event_list).to be_an_instance_of(Array)
      expect(event_list.first).to match /#{Setting.Site['code_pattern']}/
    end
  end

  it '#get_event_data' do
    stub_rest_client(:get, event1)

    event = @lc.get_event_data(event1.code)

    expect(event).to be_an_instance_of(Hash)
    expect(event).to include('code' => event1.code)
  end

  it '#get_event_data_for_year' do
    stub_rest_client(:get, [event1, event2])

    event_data = @lc.get_event_data_for_year('2014')

    expect(event_data).to be_an_instance_of(Array)
    expect(event_data.last['code']).to match /#{Setting.Site['code_pattern']}/
  end

  it '#get_members' do
    members = ['Workshop' => event1.code,
               'Membership' => { role: 'Organizer', attendance: 'Confirmed' },
               'Person' => { lastname: 'Smith', firstname: 'Agent' }]
    stub_rest_client(:get, members)

    members = @lc.get_members(event1)

    expect(members).to be_an_instance_of(Array)
    member = members.last
    expect(member['Workshop']).to eq(event1.code)
    expect(member['Membership']).to be_an_instance_of(Hash)
    expect(member['Person']).to be_an_instance_of(Hash)
  end

  it '#get_person' do
    person.legacy_id = 31337
    stub_rest_client(:get, person)

    returned_person = @lc.get_person('31337')

    expect(returned_person).to be_an_instance_of(Hash)
    expect(returned_person['legacy_id']).to eq(31337)
  end

  it '#search_person' do
    stub_rest_client(:get, person)

    returned_person = @lc.search_person('test@testing.ca')

    expect(returned_person).to be_an_instance_of(Hash)
    expect(returned_person["lastname"]).to eq(person.lastname)
  end

  it '#add_person' do
    stub_rest_client(:post, ['42'])

    legacy_id = @lc.add_person(person)

    expect(legacy_id).to eq(['42'])
  end

  context '#add_member' do
    it 'fails gracefully with invalid event code' do
      stub_rest_client(:post, ['Invalid event_id'])

      response = @lc.add_member(membership: membership1,
                                event_code: 'foo', person: person,
                                updated_by: 'RSpec Test')

      expect(response.first).to include('Invalid event_id')
    end

    it 'adds a member to given event' do
      stub_rest_client(:post, ['Added membership'])

      response = @lc.add_member(membership: membership1, event_code: '16w5666',
                                person: person, updated_by: 'RSpec Test')

      expect(response.last).to include('Added membership')
    end

  end

  it '#get_lectures' do
    stub_rest_client(:get, [{ 'legacy_id' => '123', 'event_id' => '16w5666',
                              'title' => 'An Exciting Talk' }])

    lectures = @lc.get_lectures('16w5666')

    expect(lectures.last['event_id']).to eq('16w5666')
    expect(lectures.last['legacy_id']).not_to be_nil
  end

  it '#get_lecture' do
    stub_rest_client(:get, 'legacy_id' => '123', 'event_id' => '16w5666',
                           'title' => 'An Exciting Talk')

    the_lecture = @lc.get_lecture(123)

    expect(the_lecture['title']).to eq('An Exciting Talk')
  end

  it '#add_lecture' do
    lecture = build(:lecture)
    stub_rest_client(:post, nil)
    allow(RestClient).to receive(:get).and_return({ legacy_id: 666 }.to_json)

    results = @lc.add_lecture(lecture)

    expect(results).to eq(666)
  end

  context '#delete_lecture' do
    it 'should return 0 rows if delete fails' do
      stub_rest_client(:get, [0])

      rows = @lc.delete_lecture('3682')

      expect(rows.first).to eq(0)
    end

    it 'should return 1 rows if delete is successful' do
      stub_rest_client(:get, [1])

      rows = @lc.delete_lecture('3681')

      expect(rows.first).to eq(1)
    end
  end
end
