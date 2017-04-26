json.array! @memberships['Confirmed'] do |membership|
  json.member do
    json.role membership.role
    json.name membership.person.name
    json.affiliation membership.person.affiliation
    json.email membership.person.email
    json.url membership.person.url
    json.arrival_date membership.arrival_date
    json.departure_date membership.departure_date
  end
end
