#!/usr/bin/env ruby
# frozen_string_literal: true

# Patches the Xcode project to include TorrentFlowNativeService.swift

begin
  require 'xcodeproj'
rescue LoadError
  puts "Installing xcodeproj gem..."
  system('gem install xcodeproj --no-document') || exit(1)
  require 'xcodeproj'
end

PROJECT_PATH = File.join(__dir__, '..', 'ios', 'Runner.xcodeproj')
SWIFT_FILE = 'TorrentFlowNativeService.swift'

project = Xcodeproj::Project.open(PROJECT_PATH)

# Check if already exists
if project.main_group.find_subpath(File.join('Runner', SWIFT_FILE), false)
  puts "Already in project: #{SWIFT_FILE}"
  exit 0
end

# Find Runner group and target
runner_group = project.main_group.find_subpath('Runner', false) || exit(1)
target = project.targets.find { |t| t.name == 'Runner' } || exit(1)

# Add file reference and add to Sources build phase
file_ref = runner_group.new_file(SWIFT_FILE)
target.source_build_phase.add_file_reference(file_ref)

project.save
puts "Added #{SWIFT_FILE} to Xcode project"
