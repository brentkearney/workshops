return {} unless policy(@memberships['Confirmed'].first).staff_and_admins
json.array! @memberships['Confirmed'] do |membership|
  json.person do
    json.lastname membership.person.lastname
    json.firstname membership.person.firstname
    json.email membership.person.email
    json.gender membership.person.gender
    json.affiliation membership.person.affiliation
    json.salutation membership.person.salutation
    json.url membership.person.url
    json.phone membership.person.phone
    json.fax membership.person.fax
    json.address1 membership.person.address1
    json.address2 membership.person.address2
    json.address3 membership.person.address3
    json.city membership.person.city
    json.region membership.person.region
    json.country membership.person.country
    json.postal_code membership.person.postal_code
    json.academic_status membership.person.academic_status
    json.department membership.person.department
    json.title membership.person.title
    json.phd_year membership.person.phd_year
    json.biography membership.person.biography
    json.research_areas membership.person.research_areas
    json.updated_at membership.person.updated_at
    json.emergency_contact membership.person.emergency_contact
    json.emergency_phone membership.person.emergency_phone
    json.updated_by membership.person.updated_by
  end
  json.membership do
    json.arrival_date membership.arrival_date
    json.departure_date membership.departure_date
    json.attendance membership.attendance
    json.role membership.role
    json.replied_at membership.replied_at
    json.updated_by membership.updated_by
    json.updated_at membership.updated_at
    json.has_guest membership.has_guest
    json.guest_disclaimer membership.guest_disclaimer
    json.special_info membership.special_info
    json.own_accommodation membership.own_accommodation
    json.room membership.room
    json.staff_notes membership.staff_notes
    json.invited_by membership.invited_by
    json.invited_on membership.invited_on
    json.room_notes membership.room_notes
  end
end

