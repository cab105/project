Project
=======

A simplistic project time tracker I wrote a couple of years ago to help track the
amount of time spent on various tasks for client billing or just normal day job
logistics.

Usage
-----

	project.rb project_name start
		# Start the clock for a new task

	project.rb project_name stop "message"
		# Stop the clock and use "message" as your notes

	project.rb project_name status
		# Dump all tasks associated with the project and sum the time

Upon first invocation, a new directory is created in the user's home directory
called `.project` where each project will have its own file in the format of:

	start_time;stop_time;description

Ongoing tasks will have -1 set for the stop_time and an empty string for the description.