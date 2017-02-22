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

namespace :ws do

  task :default => 'ws:print_options'

  # safe default
  task :print_options do
    puts "Options are: create_admins, nuke_data, import_year, import_month, add_lectures, update_members"
  end

  desc "Create staff and admin accounts"
  task :create_admins => :environment do
    ##
    ## Create Admin People
    ##
    Person.create([
      {
        firstname: 'System',
        lastname: 'Administrator',
        email: 'sysadmin@example.com',
        affiliation: 'Example Organization',
        title: 'System Administrator',
        gender: 'M',
        updated_by: 'Workshops'
      },
      {
          firstname: 'Another',
          lastname: 'Person',
          email: 'another@example.com',
          affiliation: 'Example Organization',
          title: 'Example Record',
          gender: 'F',
          updated_by: 'Workshops'
      }
    ])

    ## Create SuperUser User
    p = Person.find_by(email: 'sysadmin@example.com')
    u = User.find_by(email: p.email)
    if u.nil?
      user = User.new(
          email: p.email,
          password: '1234567Secret',
          password_confirmation: '1234567Secret',
          person: p,
          role: 3
      )
      user.skip_confirmation!
      user.save
    else
      u.person = p
      u.save
    end

    ## Create Staff/Admin Users
    Person.where(affiliation: 'Example Organization').each do |p|
      a = User.find_by(email: p.email)
      if u.nil?
        puts "Creating an account for #{p.name}"
        user = User.new(
            email: p.email,
            password: '1234567Secret',
            password_confirmation: '1234567Secret',
            person: p,
            role: :staff,
            location: Setting.Locations.keys.first
        )
        user.skip_confirmation!
        user.save
      else
        puts "User for #{p.name} already exists: #{u.email}, role #{u.role}"
        u.person = p
        u.save
      end
    end # create staff users
  end # task :create_admins

  ##
  ## Nuke existing records
  ##
  desc "Delete all data from development database"
  task :nuke_data => :environment do
    if Rails.env.development?
      User.delete_all
      Person.delete_all
      Event.delete_all
      Membership.delete_all
      puts "All data has been deleted from development database."
    else
      puts "Refusing to drop all data unless we're in development mode"
    end
  end

  def import_members(lc, code)
    puts
    puts "##################################"
    puts "Adding members for #{code}"
    puts "##################################"
    puts

    membership_errors = Array.new

    lc.get_members(code).each do |member|
      membership = Membership.new(member["Membership"])

      if membership.updated_by.nil?
        membership.updated_by = 'Workshops Import'
      end
      if member["Person"]["updated_by"].nil?
        member["Person"]["updated_by"] = 'Workshops Import'
      end

      membership.event = Event.find(code)

      # Check for matching local Person record
      local_person = Person.find_by(legacy_id: member['Person']['legacy_id'])
      unless local_person
        local_person = Person.find_by(email: member['Person']['email'])
      end

      if local_person
        # puts "Found! #{local_person.name} has email #{local_person.email}"
        # if local_person.legacy_id.to_i == member["Person"]["legacy_id"].to_i
        membership.person = local_person
        # else
        #   people_errors.push("Record has matching email but different legacy_id! Remote: #{member['Person']['lastname']}  #{member['Person']['legacy_id']} | Local: [#{local_person.id}]#{local_person.name} #{local_person.legacy_id}")
        # end

      else
        # Otherwise create a new person record
        membership.person = Person.new(member['Person'])
      end

      unless membership.save
        # Skip gender & affiliation checks here -- they will be caught by event sync later
        membership.errors.messages.delete(:"person.gender")
        membership.errors.messages.delete(:"person.affiliation")
        if membership.errors.messages.count > 0
          membership_errors.push("[#{code}] Member #{member['Person']['lastname']}: " + membership.errors.full_messages.to_s)
        else
          membership.save!(validate: false)
        end
      end
    end
    membership_errors
  end

  ##
  ## Populate Event data from legacy db
  ##
  desc "Import event and membership data for a given year"
  task :import_year, [:year] => :environment do |t, args|
    year = args[:year]
    if year.blank?
      abort("\nUse import_year[year]. For example `rake ws:import_year[2015]`\n")
    end

    events = Array.new
    event_errors = Array.new

    lc = LegacyConnector.new

    lc.get_event_data_for_year(year).each do |event|
      puts "Adding event: " + event["code"]
      e = Event.new(event)

      if e.save
        events << event["code"]
      else
        event_errors << "#{e.code}: #{e.errors.full_messages.to_s}"
      end
    end

    ##
    ## Populate Membership & People data from legacy db
    ##
    membership_errors = Array.new
    events.each do |code|
      membership_errors << import_members(lc, code)
    end

    puts
    puts "Errors encountered:"
    puts "~~~~~~~~~~~~~~~~~~~"
    puts "Events: "
    puts event_errors.to_yaml
    puts
    puts "Memberships: "
    puts membership_errors.to_yaml
    puts

  end

  desc "Import event and membership data for a given month"
  task :import_month, [:yearmonth] => :environment do |t, args|
    year_month = args[:yearmonth]
    unless year_month.length == 6
      abort("\nUse import_month[YYYYMM]. For example `rake ws:import_month[201509]`\n")
    end

    puts "Fetching events in #{year_month}"

    events = Array.new
    event_errors = Array.new
    membership_errors = Array.new

    lc = LegacyConnector.new
    lc.list_events(year_month, year_month).each do |code|
      puts "Adding event: #{code}"
      events << code
      e = Event.new(lc.get_event_data(code))
      unless e.save
        event_errors << "#{e.code}: #{e.errors.full_messages.to_s}"
      end
    end

    puts "Retrieved #{events.count} events!"
    if event_errors
      puts "\nEvent creation errors: "
      puts event_errors.to_yaml
    end
    if membership_errors
      puts "\nMembership creation errors: "
      puts membership_errors.to_yaml
    end

  end


  ##
  ## Add local lectures to legacy db
  ##
  desc "Add lectures to legacy db for a given event"
  task :add_lectures, [:event_id] => :environment do |t, args|
    event_id = args[:event_id]
    if event_id.blank?
      abort("\nUse add_lectures[event_code]. For example `rake ws:add_lectures[\"15w5012\"]`\n\n")
    end

    event = Event.find(event_id)

      LC = LegacyConnector.new
      puts "\nAdding lectures from local #{event_id} to remote database:\n"

      Event.find("#{event_id}").lectures.each do |lecture|
        puts "Adding lecture: #{lecture.start_time} to #{lecture.end_time}: #{lecture.person.lname}"
        LC.add_lecture(lecture)
      end

    puts "\nFinished adding lectures to #{event_id}.\n"
  end


  ##
  ## Update Event memberships for given event
  ##
  desc "Update membership & person data for a given event"
  task :update_members, [:code] => :environment do |t, args|
    code = args[:code]
    abort("\nUse update_members[event_code]. For example `rake ws:update_members[15w5069]`\n") if code.blank?
    event = Event.find("#{code}")
    abort("\nNo event found with code: #{code}\n") if event.nil?
    local_members = event.memberships

    LC = LegacyConnector.new
    remote_members = LC.get_members("#{code}")
    if remote_members
      puts "\n\nRetrieved #{remote_members.count} remote members for #{code}.\n"
    else
      abort("\n\nError: unable to retrieve any remote members for #{code}!\n\n")
    end

    remote_members.each do |remote|
      puts "\n\nImporting remote person: " + remote['Person']['firstname'] + ' ' + remote['Person']['lastname'] + "...\n"

      if remote['Person']['updated_by'].nil?
        remote['Person']['updated_by'] = 'Workshops Import'
      end
      if remote['Membership']['updated_by'].nil?
        remote['Membership']['updated_by'] = 'Workshops Import'
      end

      local_person = Person.find_by(legacy_id: remote['Person']['legacy_id'])
      unless local_person
        local_person = Person.find_by(email: remote['Person']['email'])
      end

      if local_person
        puts "\n\nFound local person: #{local_person.name}:"
        puts local_person.to_json
        puts "Updating with:"
        puts remote['Person'].to_s

        remote['Person'].each_pair do |k,v|
          local_person[k] = v unless v.blank?
        end
        local_person['updated_at'] = DateTime.now if local_person['updated_at'].blank?

        puts "Local (unsaved) record is now:"
        puts local_person.to_json
        local_person.save!
      else
        puts "Creating new local person: #{remote['Person']['firstname']} #{remote['Person']['lastname']}"
        local_person = Person.create!(remote['Person'])
      end

      local_membership = local_members.find {|lm| lm.person_id == local_person.id }

      if local_membership
        puts "Found local #{code} membership for #{local_person.name}. Updating with:"
        puts remote['Membership'].to_s
        remote['Membership'].each_pair do |k,v|
          local_membership[k] = v unless v.blank?
        end
        local_membership.save!
        puts "Updated membership:"
        puts local_membership.to_json
      else
        puts "Creating new #{code} membership for #{local_person.name}."
        new_membership = Membership.new(remote['Membership'])
        new_membership.event = event
        new_membership.person = local_person
        new_membership.save!
        puts "New membership:"
        puts new_membership.to_json
      end

    end
  end

end
