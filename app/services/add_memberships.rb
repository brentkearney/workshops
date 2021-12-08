# adds people and event memberships from API

class AddMemberships
  attr_reader :errors

  def initialize(memberships, event, updated_by)
    @memberships = memberships || []
    @event = event
    @updated_by = updated_by
    @errors = []
  end

  def save
    @memberships.each do |member|
      person = find_or_create(member['person'])
      membership = Membership.new(sync_memberships: true, event: @event,
                                  person: person, role: member['role'],
                                  updated_by: @updated_by)

      unless membership.save
        @errors << membership.errors.full_messages
      end
    end

    @errors.empty?
  end

  private

  def find_or_create(person_data)
    return if person_data.blank?

    person = Person.new(member_import: true, updated_by: @updated_by)
    person.assign_attributes(person_data)

    if person.email.blank?
      @errors << "Missing email for person: #{person_data}"
      return
    end

    existing_person = Person.find_by(email: person.email)
    if existing_person.present?
      existing_person.assign_attributes(person_data)
      existing_person.updated_by = @updated_by
      existing_person.member_import = true
      return existing_person
    end

    person
  end
end
