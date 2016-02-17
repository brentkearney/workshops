# Copyright (c) 2016 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

require 'rails_helper'

RSpec.describe "Model validations: Person", type: :model do
  it "has valid factory" do
    expect(FactoryGirl.create(:person)).to be_valid
  end

  it 'requires a firstname' do
    p = FactoryGirl.build(:person, firstname: '')
    expect(p.valid?).to be_falsey
  end

  it "requires a lastname" do
    p = FactoryGirl.build(:person, lastname: '')
    expect(p.valid?).to be_falsey
  end

  it "requires an email" do
    p = FactoryGirl.build(:person, email: '')
    expect(p.valid?).to be_falsey
  end

  it "requires a gender" do
    p = FactoryGirl.build(:person, gender: '')
    expect(p.valid?).to be_falsey
  end

  it "requires an affiliation" do
    p = FactoryGirl.build(:person, affiliation: '')
    expect(p.valid?).to be_falsey
  end

  it "requires a unique, case insensitive email address" do
    person1 = FactoryGirl.create(:person)
    expect(person1).not_to be_nil

    person2 = FactoryGirl.build(:person, email: person1.email.upcase)
    expect(person2.valid?).to be_falsey
    expect(person2.errors[:email].first).to eq("has already been taken")
  end
  
  context 'Decorator functions' do
    before do
      @person = FactoryGirl.create(:person)
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
  end


  #it "should have an is_admin? method that returns true if person is an admin user and false otherwise"
  # do
  #   person = FactoryGirl.create(:person)
  #   Account.create!(account_attributes(person:person))
  #
  #   expect(person.is_admin?).to be(false)
  #   person.account.admin_level = 5
  #   person.save!
  #   expect(person.is_admin?).to be(true)
  # end

  # describe "Synchronizes with Legacy Database (ldb)" do
  #   it "uses existing ldb record, if one exists, instead of creating a new one"
  #   it "adds new records to ldb, if they don't already exist"
  #   it "updates ldb version of record, unless it is newer"
  #   it "updates local record when ldb record is updated"
  # end
end
