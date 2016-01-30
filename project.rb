#!/usr/bin/env ruby

# project.rb - A script to perform project logging, by recording the start and
# end time, and also a description of what was done during that block of time.
# The theory goes that this should allow for a somewhat accurate form of
# project reporting based on time.
#
# Expected execution:
#   project.rb ProjectName action [message]
# Where action can consist of:
#   start - Create a new entry, and start the clock.  This does not require a
#     message.
#   stop - Stop the clock for the most recent entry.  This will require a
#     message from the command line.
#   status - Dump a summary of the time spent on the project, and a running
#     total.
# 
# Note: Project information will be stored in ~/.project/ProjectName
#
# Created by Chris Baumbauer <cab@cabnetworks.net>
require 'fileutils'
require 'date'

# Global definitions
dirLoc = ENV['HOME'] + '/.project'

def printUsage
  puts "project.rb ProjectName action [message]\n"
  puts "Where action can consist of:\n"
  puts "\tstart - Create a new entry and start the clock.  This does not\n"
  puts "\t\trequire a message.\n"
  puts "\tstop - Stop the clock for the most recent entry.  This will\n"
  puts "\t\trequire a message.\n"
  puts "\tabort - Stop the most recent activity and ignore it."
  puts "\tstatus - Dump a summary of the time spent on the project and\n"
  puts "\t\ta current running total of time spent on the project.\n\n"
  Kernel.exit(1)
end

def handleStart(directoryLocation, projectName)
  unless File.directory?(directoryLocation)
    puts "Directory #{directoryLocation} doesn't exist.  Creating...\n"
    FileUtils.mkdir(directoryLocation)
  end
  
  file = directoryLocation << '/' << projectName
  puts "Starting new task for project: #{projectName}\n"
  if File.file?(file)
    # The file exists.  Check if there's a task already open, and then add it
    # XXX: Add case for a file with no data to parse
    f = File.new(file, "r+")
    pe = ProjectEntry.new
    while line = f.gets
      if line.start_with?("#")
        next
      end
      pe.import(line)
      if pe.stopTime.instance_of?(String) and pe.stopTime.match("^-1$")
        f.close
        puts "There is already a task open: #{pe.startTime}\n"
        Kernel.exit
      end
    end
    # If we hit this point, then there are no open tasks, so lets create one.
    pe.startTask
    f.puts "#{pe}\n"
    f.close
    Kernel.exit
  else
    # Given the fact that the file doesn't exist, this must be the first entry
    f = File.new(file, "w+")
    pe = ProjectEntry.new
    pe.startTask
    f.puts "#{pe}\n"
    f.close
  end
end

def handleAbort(directoryLocation, projectName)
  # Verify the project directory
  unless File.directory?(directoryLocation)
    puts "Directory #{directoryLocation} doesn't exist.  Exiting...\n"
    Kernel.exit(3)
  end

  # Verify the project file
  fileName = directoryLocation << '/' << projectName;
  unless File.file?(fileName)
    puts "Project #{projectName} doesn't exist.  Exiting...\n"
    Kernel.exit(3)
  end

  # Open the file, build an array of entries, add in the end time, and write.
  if File.file?(fileName)
    f = File.new(fileName, "r+")
    peArray = Array.new
    while line = f.gets
      if line.start_with?("#")
        next
      end
      pe = ProjectEntry.new
      pe.import(line)
      peArray.push(pe)
    end
    f.close
    # Verify that the last element has an open task
    unless peArray[-1].stopTime.instance_of?(String) and peArray[-1].stopTime.match("^-1$")
      puts "There are no tasks open.\n"
      Kernel.exit(3)
    else
      peArray[-1] = nil
    end

    f = File.new(fileName, "w")
    peArray.each do |pe|
      if pe.nil?
        next
      end
      f.puts "#{pe}\n"
    end
    f.close
  else
    puts "The project: #{projectName} does not exist.  Create it first by starting a task\n"
    Kernel.exit(3)
  end
end

def handleStop(directoryLocation, projectName, msg)
  # Verify the project directory
  unless File.directory?(directoryLocation)
    puts "Directory #{directoryLocation} doesn't exist.  Exiting...\n"
    Kernel.exit(3)
  end
  
  # Verify the project file
  fileName = directoryLocation << '/' << projectName;
  unless File.file?(fileName)
    puts "Project #{projectName} doesn't exist.  Exiting...\n"
    Kernel.exit(3)
  end
  
  # Verify a message exists
  if msg.empty?
    puts "A message string is required to finish a task.\n"
    Kernel.exit(3)
  end
  
  # Open the file, build an array of entries, add in the end time, and write.
  if File.file?(fileName)
    f = File.new(fileName, "r+")
    peArray = Array.new
    while line = f.gets
      if line.start_with?("#")
        next
      end
      pe = ProjectEntry.new
      pe.import(line)
      peArray.push(pe)
    end
    f.close
    # Verify that the last element has an open task
    unless peArray[-1].stopTime.instance_of?(String) and peArray[-1].stopTime.match("^-1$")
      puts "There are no tasks open.\n"
      Kernel.exit(3)
    else
      peArray[-1].finishedTask(msg)
    end
    
    f = File.new(fileName, "w")
    peArray.each do |pe|
      f.puts "#{pe}\n"
    end
    f.close
  else
    puts "The project: #{projectName} does not exist.  Create it first by starting a task\n"
    Kernel.exit(3)
  end
end

def handleStatus(directoryLocation, projectName)
  fileName = directoryLocation << '/' << projectName;
  unless File.file?(fileName)
    puts "The project: #{projectName} doesn't exist.\n"
    Kernel.exit(4)
  end
  
  f = File.new(fileName, "r")
  peArray = Array.new
  while line = f.gets
    if line.start_with?("#")
      next
    end
    pe = ProjectEntry.new
    pe.import(line)
    peArray.push(pe)
  end
  f.close
  
  puts "Time (hrs)\tStart Time\tLog"
  (1..40).each do
    print '='
  end
  puts "\n"
  
  summary = 0
  peArray.each do |pe|
    if pe.stopTime.instance_of?(String) and pe.stopTime.match("^-1$")
	  printf "%0.4f\t%s\t## ON-GOING ##\n", pe.convTime(DateTime.now) - pe.convTime(pe.startTime), pe.startTime
      next
    end
    summary += pe.elapsedTime
    printf "%0.4f\t%s\t%s\n", pe.elapsedTime, pe.startTime, pe.message
  end
  
  (1..40).each do
    print '='
  end
  printf "\n%0.4f\t\tTotal time\n", summary
end

# Class definitions
class ProjectEntry
  attr_reader :stopTime, :startTime, :message
  def startTask
    @startTime = DateTime.now
    @stopTime = "-1"
    @message = ""
  end
  
  def finishedTask(message)
    @message = message
    @stopTime = DateTime.now
  end
  
  def elapsedTime
    if @stopTime.instance_of?(String)
      return 0
    end
    
	return convTime(@stopTime) - convTime(@startTime)
  end
  
  def import(str)
    start, stop, @message = str.chomp.split(/;/)
    @startTime = DateTime.parse(start)
    if stop.match("^-1$")
      @stopTime = "-1"
    else
      @stopTime = DateTime.parse(stop)
    end
  end
  
  def to_s
    return "#{@startTime};#{@stopTime};#{@message}"
  end

  # Convert the project time difference to fractions of an hour
  def convTime(ts)
    s = ts.strftime("%s")
    return s.to_i/3600.0
  end
end

# BEGIN MAIN EXECUTION HERE
# First, check the arguments, and parse them
if ARGV.length < 2 or ARGV.length > 3
  puts "Invalid number of arguments\n"
  printUsage
end

projectName = ARGV.shift
action = ARGV.shift
message = ""
if ARGV.length == 1
  message = ARGV.shift
end

# Verify the action
if (((action <=> "start") != 0) and ((action <=> "stop") != 0) and
  ((action <=> "status") != 0)) and ((action <=> "abort") != 0)
  puts "Invalid action: #{action}\n"
  printUsage
end

# Perform status action
if (action.match("status"))
  handleStatus(dirLoc, projectName)
end

# Perform stop action
if (action.match("stop"))
  handleStop(dirLoc, projectName, message)
end

# Perform start actions
if (action.match("start"))
  handleStart(dirLoc, projectName)
end

# Abort the current operation
if (action.match("abort"))
  handleAbort(dirLoc, projectName)
end
