# The default location set in new schedule items
Rails.application.config.x.default_locations = {
    '5 Day Workshop'          => 'TCPL 201',
    '2 Day Workshop'          => 'TCPL 201',
    'Summer School'           =>  'TCPL 202',
    'Focussed Research Group' =>  'TCPL 202',
    'Research in Teams'       => 'TCPL 107'
}

# A list of locations for the schedule form suggestions
Rails.application.config.x.locations = [
    'Corbett Hall', 'Corbett Hall Lounge (CH 5210)', 'Corbett Hall Reading Room (CH 5310)',
    'TCPL', 'TCPL Foyer', 'Vistas Dining Room', 'Banff National Park'
]