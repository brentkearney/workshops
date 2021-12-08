require 'rails_helper'

describe "AddMemberships" do
  before do
    @memberships = [
      {
        "role" => "Participant",
        "person" => build(:person).as_json
      },
      {
        "role" => "Organizer",
        "person" => build(:person).as_json
      }
    ]
    @event = create(:event)
    @updated_by = 'AddMemberships spec'
  end

  context '.initialize' do
    it 'initializes with memberships, event, and updated_by' do
      add_members = AddMemberships.new(@memberships, @event, @updated_by)
      expect(add_members.class).to eq(AddMemberships)
    end

    it 'has an errors accessor that is an array' do
      add_members = AddMemberships.new(@memberships, @event, @updated_by)
      expect(add_members.errors.class).to eq(Array)
    end

    it 'handles nil memberships' do
      add_members = AddMemberships.new(nil, @event, @updated_by)
      expect(add_members.class).to eq(AddMemberships)
      expect(add_members.errors).to be_empty
    end
  end

  context '.save' do
    it 'saves the memberships' do
      add_members = AddMemberships.new(@memberships, @event, @updated_by)
      expect(add_members.save).to be_truthy
      expect(@event.memberships.count).to eq(2)
    end

    it 'reports errors' do
      membership = [
        {
          "role" => "Participant",
          "person" => build(:person, lastname: nil).as_json
        }
      ]
      add_members = AddMemberships.new(membership, @event, @updated_by)
      expect(add_members.save).to be_falsey
      expect(add_members.errors).not_to be_empty
    end

    it 'updates existing records' do
      person = create(:person)
      membership = [
        {
          "role" => "Participant",
          "person" => { "email" => person.email, "lastname" => 'Smith' }
        }
      ]

      add_members = AddMemberships.new(membership, @event, @updated_by)

      expect(add_members.save).to be_truthy
      person = Person.find(person.id)
      expect(person.lastname).to eq('Smith')
      expect(person.updated_by).to eq('AddMemberships spec')
    end
  end
end
