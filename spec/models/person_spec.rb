# Copyright (c) 2016 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

require 'rails_helper'

RSpec.describe 'Model validations: Person', type: :model do
  it 'has valid factory' do
    expect(create(:person)).to be_valid
  end

  it 'requires a firstname' do
    p = build(:person, firstname: '')
    expect(p.valid?).to be_falsey
  end

  it 'requires a lastname' do
    p = build(:person, lastname: '')
    expect(p.valid?).to be_falsey
  end

  it "requires an email" do
    p = build(:person, email: '')
    expect(p.valid?).to be_falsey
  end

  it 'does not require a gender' do
    p = build(:person, gender: '')
    expect(p.valid?).to be_truthy
  end

  it 'requires a gender if :is_rsvp' do
    p = build(:person, gender: '', is_rsvp: true)
    expect(p.valid?).to be_falsey
  end

  it 'requires a country if :is_rsvp' do
    p = build(:person, country: '', is_rsvp: true)
    expect(p.valid?).to be_falsey
  end

  it 'requires a region if country is Canada or USA' do
    p = build(:person, country: 'Canada', region: nil)
    expect(p.valid?).to be_falsey
    p.region = 'ON'
    expect(p.valid?).to be_truthy

    p.country = 'USA'
    p.region = ''
    expect(p.valid?).to be_falsey
    p.region = 'VA'
    expect(p.valid?).to be_truthy
  end

  it 'sets country to "USA" if country is analogous' do
    p = build(:person, country: 'United States')
    p.save
    p = Person.find(p.id)
    expect(p.country).to eq('USA')

    p.country = 'U.S.A.'
    p.save
    expect(Person.find(p.id).country).to eq('USA')

    p.country = 'U.S.'
    p.save
    expect(Person.find(p.id).country).to eq('USA')
  end

  it 'does not require a gender if importing memberships' do
    p = build(:person, gender: '', member_import: true)
    expect(p.valid?).to be_truthy
  end

  it 'requires an affiliation' do
    p = build(:person, affiliation: '')
    expect(p.valid?).to be_falsey
  end

  it 'does not require an affiliation if importing memberships' do
    p = build(:person, affiliation: '', member_import: true)
    expect(p.valid?).to be_truthy
  end

  it 'requires a unique, case insensitive email address' do
    person1 = create(:person)
    person2 = build(:person, email: person1.email.upcase)

    expect(person2.valid?).to be_falsey
    expect(person2.errors[:email].first).to eq('has already been taken')
  end

  it 'requires an address only if :is_organizer_rsvp' do
    p = build(:person, address1: '')
    expect(p).to be_valid

    p.is_organizer_rsvp = true
    expect(p).not_to be_valid
  end

  it 'requires academic_status only if :is_rsvp' do
    p = build(:person, academic_status: '')
    expect(p).to be_valid

    p.is_rsvp = true
    expect(p).not_to be_valid
  end

  context 'Decorator functions' do
    before do
      @person = create(:person)
    end

    it ".name returns 'firstname lastname'" do
      expect(@person.name).to eq("#{@person.firstname} #{@person.lastname}")
    end

    it ".lname returns 'lastname, firstname'" do
      expect(@person.lname).to eq("#{@person.lastname}, #{@person.firstname}")
    end

    context 'Department is set' do
      it '.affil returns "affiliation, department"' do
        expect(@person.affil).to eq("#{@person.affiliation}, #{@person.department}")
      end
    end

    context 'Department is not set' do
      before :each do
        @person.department = nil
      end
      it '.affil returns affiliation' do
        expect(@person.affil).to eq("#{@person.affiliation}")
      end
    end

    context 'Title is set' do
      before :each do
        @person.title = 'Master of Disguise'
      end
      it '.affil_with_title returns "affil — title"' do
        expect(@person.affil_with_title).to eq("#{@person.affil} — #{@person.title}")
      end
    end

    context 'Title is not set' do
      before :each do
        @person.title = nil
      end
      it '.affil_with_title returns "affil — academic_status"' do
        @person.academic_status = 'Professor'
        expect(@person.affil_with_title).to eq("#{@person.affil} — #{@person.academic_status}")
      end
    end

    context 'Salutation is set' do
      it '.dear_name returns "Salutation Lastname"' do
        expect(@person.dear_name).to eq("#{@person.salutation} #{@person.lastname}")
      end
    end

    context 'Salutation is not set' do
      before :each do
        @person.salutation = nil
      end

      it '.dear_name returns "Prof. Lastname" if academic_status is Professor' do
        @person.academic_status = 'Professor'
        expect(@person.dear_name).to eq("Prof. #{@person.lastname}")
      end

      it '.dear_name returns "Firstname Lastname"' do
        @person.academic_status = nil
        expect(@person.dear_name).to eq("#{@person.firstname} #{@person.lastname}")
      end
    end

    context 'Gender is "M"' do
      before :each do
        @person.gender = 'M'
      end
      it '.his_her returns "his"' do
        expect(@person.his_her).to eq('his')
      end
    end

    context 'Gender is "F"' do
      before :each do
        @person.gender = 'F'
      end
      it '.his_her returns "her"' do
        expect(@person.his_her).to eq('her')
      end
    end

    context '.uri' do
      it 'if url is valid, returns it' do
        expect(@person.uri).to eq(@person.url)
      end

      it 'if url is missing protocol, prepends it' do
        @person.url = 'google.com'
        @person.save

        expect(@person.uri).to eq('http://google.com')
      end
    end
  end
end
