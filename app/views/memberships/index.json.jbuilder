member = @event.memberships.first
if policy(member).staff_and_admins
  allowed_fields = policy(member).allowed_fields?
  person_fields = allowed_fields.last.values.first
  Membership::ATTENDANCE.each do |status|
    json.set! status do
      json.array! @memberships[status] do |membership|
        json.person do
          json.merge! membership.person.attributes.select { |k,v| person_fields.include? k.to_sym }
        end
        json.membership do
          json.merge! membership.attributes.select { |k,v| allowed_fields.include? k.to_sym }
        end
      end
    end
  end
else
  json.array! @memberships['Confirmed'] do |membership|
    json.member do
      json.role membership.role
      json.name membership.person.name
      json.affiliation membership.person.affiliation
      json.url membership.person.url
    end
  end
end
