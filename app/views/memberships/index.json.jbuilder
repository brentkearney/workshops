json.array! @memberships['Confirmed'] do |membership|
  json.member do
    json.role membership.role
    json.name membership.person.name
    json.affiliation membership.person.affiliation
    json.url membership.person.url
  end
end
