# Workshops

"Workshops" is software for managing small conferences. It is made with [Ruby on Rails](http://rubyonrails.org)
and released under the GPL-A open-source license. The software is intended for institutions/organizations
who host workshops. Although it is in production use at the
[Banff International Research Station](https://workshops.birs.ca/events/future), it is still in the early
stages of development &mdash; meaning it is not yet ready for use by other organizations because there are
not enough features for general use.

However, contributions are most welcome. If you would like to add features yourself, please
[let me know](mailto:brentk@birs.ca), and/or submit a Pull Request. Or if you would like to pay for the development of additional features, please [contact me](mailto:brent@netmojo.ca).


Installation instructions are below.

### Current Features
* **Sign-ins and sign-ups** for authorized event members, staff, and admin.
* **Workshop scheduling**: organizers can enter their workshop schedules, including talks with abstracts/descriptions, and choose when to publish their schedules to the public.
* Default schedule templates that staff can edit. Defaults get applied to all workshop's schedules which have not yet been edited.
* **LaTeX formatting** in all text editing areas, via [MathJax](https://www.mathjax.org), for mathematical formulae.
* **JSON output** of schedules and other event data, for easy display on external websites, [like this](http://www.birs.ca/events/2017/5-day-workshops/17w5030/schedule).
* **Event Invitations** feature sends a unique link to potential participants, inviting them to attend a workshop.
* **RSVPs** allows invited participants to reply to their invitation with "Yes", "No", "Maybe". Includes a text area to send a personal note to the organizer. If confirming, collects data for hotel reservations, etc., via a web form that is optimized for autofill. Automatically sends confirmation email to confirmed participants, using email templates based on workshop type.
* **Email notifications** for staff and organizers when data changes, such as participant RSVPs and schedule updates during currently running workshops.
* **Multiple locations** for events. Each location has its own settings, email templates, etc..
* **Event listing navigation** by user's events, future events, past events, events by location, and by year.
* **Event participant listings** grouped by attendance status (Confirmed, Invited, Declined, etc..), click for more detailed profile views of each participant.
* **Email everyone buttons** Convenience buttons to email all participants, or all organizers of an event (uses Bcc).
* **Fine-grained role-based access controls** for many features allowing different levels of privilege between admin, staff, organizers and participants.
* **Data imports** Workshop data is imported via calls to an external API, JSON.
* **Background jobs** to sync event membership data with external data source via API, and to send emails.
* **Authenticated JSON API** for [an external video recording system](http://www.birs.ca/facilities/automated-video) to update lecture records based on recordings made.
* **Settings in database** Application settings are stored in the database instead of config files, allowing staff and admins to easily change settings with web interface, on the fly.


### Upcoming Features:
* Integration with external [email delivery service](https://www.sparkpost.com), with email template management and delivery tracking.
* Staff and Organizers can add members to their workshop (currently participants are added by external program and imported via API).
* API integration with the Visual One room booking software, used by many hotels and conference centers, for automatic room booking.
* Staff can assign hotel rooms, generate reports for hotel room bookings, and manage other hospitality details for workshop participants.
* Task scheduler, to allow automated performance of tasks such as reminder emails for participants to RSVP, room booking tasks, etc..
* Staff and admin can create new events (currently they're imported via API).
* Admin users can manage other users (add/remove/change passwords, etc) - currently they can only change their own passwords.
* Drag & drop interface to more easily re-arrange schedule items.
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
3. Read the instructions at the top of docker-compose.yml (to create data-containers, if desired)
4. Edit the lib/tasks/ws.rake file to change default user account information, noting passwords.
5. Run `docker-compose up`
6. Login to the web interface, and visit /settings. Update the Site settings with correct info.

After the first time you run it, you will pobably want to edit the entrypoint.sh script, and comment out some of it, such as running migrations, updating RVM, etc..



### License:
Workshops is free software: you can redistribute it and/or modify it under
the terms of the GNU Affero General Public License as published by the Free
Software Foundation, version 3 of the License. See the [COPYRIGHT](COPYRIGHT)
file for details and exceptions.
