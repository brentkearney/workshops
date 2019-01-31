# Workshops

"Workshops" is software for managing scientific meetings, or small conferences. It is made with [Ruby on Rails](http://rubyonrails.org)
and released under the GPL-A open-source license. The software is intended to be used by institutions/organizations
who host workshops. It is used at the
[Banff International Research Station](https://workshops.birs.ca/events/future) for a limited number of functions: inviting (but not yet adding)
people to be participants in workshops, managing their online reply to invitations (RSVP), editing member records, rudimentary scheduling functions,
and simple workshop mailling lists.

Contributions to the project are most welcome. If you would like to add features yourself, please
[let me know](mailto:brentk@birs.ca), and/or submit a Pull Request. Or if you would like to pay for the development of additional features,
please [contact me](mailto:brent@netmojo.ca).


Installation instructions are below.

### Current Features
* **Sign-ins and sign-ups** for authorized event members, staff, and admin.
* **Event Invitations** feature sends a unique link to potential participants, inviting them to attend a workshop.
* **[SparkPost](https://www.sparkpost.com) Integration** for improved email deliverability.
* **RSVPs** allows invited participants to reply to their invitation with "Yes", "No", "Maybe". Includes a text area to send a personal note to the organizer. If confirming, collects data for hotel reservations, etc., via a web form that is optimized for autofill. Automatically sends confirmation email to confirmed participants, using email templates based on workshop type.
* **Workshop scheduling**: organizers can enter their workshop schedules, including talks with abstracts/descriptions, and choose when to publish their schedules to the public.
* **Authenticated JSON API** for [an external video recording system](http://www.birs.ca/facilities/automated-video) to update lecture records in the schedule, based on recordings made.
* **Default schedule templates** that staff can edit. Defaults get applied to all workshops' schedules which have not yet been edited.
* **LaTeX formatting** in all text editing areas, via [MathJax](https://www.mathjax.org), for mathematical formulae.
* **JSON output** of schedules and other event data, for easy display on external websites, [like this](http://www.birs.ca/events/2017/5-day-workshops/17w5030/schedule).
* **Email notifications** for staff and organizers when data changes, such as participant RSVPs and schedule updates during currently running workshops.
* **Multiple locations** for events. Each location has its own settings, email templates, etc..
* **Event listing navigation** by user's events, future events, past events, events by location, and by year.
* **Event participant listings** grouped by attendance status (Confirmed, Invited, Declined, etc..), click for more detailed profile views of each participant.
* **eMail lists** send email to a single address, to have it redistributed to event members.
* **Fine-grained role-based access controls** for many features allowing different levels of privilege between admin, staff, organizers and participants.
* **Data imports** Workshop data is imported via calls to an external API, JSON.
* **Background jobs** to sync event membership data with external data source via API, and to send emails.
* **Settings in database** Application settings are stored in the database instead of config files, allowing staff and admins to easily change settings with web interface, on the fly.


### Upcoming Features:
* Staff and Organizers can add members to their workshop (currently participants are added by external program and imported via API).
* After-event feedback forms - automatically mail participants after an event, with one-click URL for providing feedback on the event.
* API integration with the Visual One room booking software, used by many hotels and conference centers, for automatic room booking.
* Staff can assign hotel rooms, generate reports for hotel room bookings, and manage other hospitality details for workshop participants.
* Task scheduler, to allow automated performance of tasks such as reminder emails for participants to RSVP, room booking tasks, etc..
* Staff and admin can create new events (currently they're imported via API).
* Admin users can manage other users (add/remove/change passwords, etc) - currently they can only change their own passwords.
* Drag & drop interface for scheduling features.
* When organizers schedule a participant to give a talk, members optionally get notified with a link to fill in the talk title and abstract.
* Addition of a forum/mail list software for each workshop, such as [Discourse](http://www.discourse.org).
* Crowd-sourcing feature for workshop participants to post open problems to the public, soliciting solutions.


### Installation Instructions:
The application is setup to work in a [Docker](http://www.docker.com) container.

1. Clone the repository: `git clone https://github.com/brentkearney/workshops.git`
2. Copy the example config files, and customize them to suit your needs. These include:
  ```
  ./docker-compose.yml.example
  ./Dockerfile.example
  ./entrypoint.sh.example
  ./nginx.conf.erb.example
  ./Passengerfile.json.example
  ```
  Bash command to copy them all to new names:
  ```
  for file in `ls -1 *.example`; do newfile=`echo $file | sed 's/\.example$//'`; cp $file $newfile; done
  ```
3. Edit docker-compose.yml to set your preferred usernames and password in the environment variables. Note the instructions
   at the top for creating data containers, for storing database and ruby gems.

   The first time the database container is run, databases and database accounts will be created via the script at
   ./db/pg-init/init-user-db.sh. It uses the environment variables that you set in docker-compose.yml.
4. Edit the lib/tasks/ws.rake file to change default user account information, setting your own passwords.
5. Run `docker-compose up` (or possibly `docker build .` first).
6. Login to the web interface (http://localhost) with your admin account, and visit /settings (click the drop-down menu in the
   to-right and choose "Settings"). Update the Site settings with your preferences.

After the first time you run it, you will pobably want to edit the entrypoint.sh script, and comment out some of it, such as running migrations, updating RVM, etc..



### License:
Workshops is free software: you can redistribute it and/or modify it under
the terms of the GNU Affero General Public License as published by the Free
Software Foundation, version 3 of the License. See the [COPYRIGHT](COPYRIGHT)
file for details and exceptions.
