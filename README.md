# Workshops

"Workshops" is software for managing small conferences. It is made with [Ruby on Rails](http://rubyonrails.org)
and released under the GPL-A open-source license. The software is intended for institutions/organizations
who host workshops. Although it is in production use at the
[Banff International Research Station](https://workshops.birs.ca/events/future), it is still in the early
stages of development &mdash; meaning it is not yet ready for use by other organizations because there are
not enough features yet.

However, contributions are most welcome. If you would like to add features yourself, please
[let me know](mailto:brentk@birs.ca), and/or submit a Pull Request. Or if you would like to pay me to
develop features for you, please [contact me](mailto:brent@netmojo.ca).


Installation instructions are below.

### Current Features
* Sign-ins and sign-ups for authorized event members, staff, and admin.
* Workshop scheduling: organizers can enter their workshop schedules, including talks with abstracts/descriptions, and choose when to publish their schedules to the public.
* Default schedule templates that staff can edit. Defaults get applied to all workshop's schedules which have not yet been edited.
* All text editing areas support LaTeX formatting via [MathJax](https://www.mathjax.org), for mathematical formulae.
* Schedules and most data from Workshops is accessible via JSON, for easy display on external websites, [like this](http://www.birs.ca/events/2017/5-day-workshops/17w5030/schedule).
* Staff get email notifications when schedules of currently running workshops are updated.

* Event Invitations feature sends a unique link to invited participants for RSVP to the event.
* RSVP feature allows invited participants to confirm or decline the invitation, and send messages to the organizer. If confirming, collects data for hotel reservations and other needs via web form, optimized for autofill. Automatically sends confirmation email to confirmed participants, and automatically notifies organizers of all RSVP replies.

* Supports events in multiple locations, each location having its own default settings, email templates, etc..
* List of workshops can be navigated by user's events, future events, past events, events by location, and by year.
* List of a workshop's participants grouped by attendance status (Confirmed, Invited, Declined, etc..), with more detailed profile views of each participant.
* Convenience buttons to email all participants, or all organizers of an event.
* Fine-grained role-based access controls for many features allowing different levels of privilege between admin, staff, organizers and participants.

* Workshop data is imported via calls to an external API.
* Background jobs to sync event membership data with external data source via API.
* Authenticated JSON API for [an external video recording system](http://www.birs.ca/facilities/automated-video) to update lecture records based on recordings made.
* Application settings are stored in the database, allowing staff and admins to easily change settings with web interface.


### Upcoming Features:
* Integration with external email delivery service, with email template management.
* Staff and Organizers can add and invite members to their workshop.
* API integration with the Visual One room booking software, used by many hotels and conference centers, for automatic room booking.
* Staff can assign hotel rooms, generate reports for hotel room bookings, and manage other hospitality details for workshop participants.
* Scheduled tasks, such as reminder emails for participants to RSVP, room booking tasks, etc..
* Staff and admin can create new events.
* Admin users can manage other users (add/remove/change passwords, etc).
* Drag & drop interface to re-arrange schedule items.
* When organizers schedule a participant to give a talk, members optionally get notified with a link to fill in the talk title and abstract.
* Addition of a forum/mail list software for each workshop, such as [Discourse](http://www.discourse.org).
* Crowd-sourcing feature for workshop participants to post open problems to the public, soliciting solutions.


### Installation Instructions:
The application is setup to work in [Docker](http://www.docker.com) containers, in development mode.

1. Clone the repository: `git clone https://github.com/brentkearney/workshops.git`
2. Copy the example config files, and customize them to suit your needs. These include:
  ```
  ./docker-compose.yml.example
  ./Dockerfile.example
  ./entrypoint.sh.example
  ./nginx.conf.erb.example
  ./Passengerfile.json.example
  ```
3. Read the instructions at the top of docker-compose.yml (create data-containers)
4. Edit the lib/tasks/ws.rake file to change default user account information, noting passwords.
5. Run `docker-compose up`
6. Login, and visit /settings. Update the Site settings with correct info.

After the first time you run it, you will pobably want to edit the entrypoint.sh script, and comment out some of it, such as running migrations, updating RVM, etc..



### License:
Workshops is free software: you can redistribute it and/or modify it under
the terms of the GNU Affero General Public License as published by the Free
Software Foundation, version 3 of the License. See the [COPYRIGHT](COPYRIGHT)
file for details and exceptions.
