#!/usr/bin/env ruby

require 'rake/clean'
require 'rake/testtask'

task :default => :test

Rake::TestTask.new(:test) do |t|
  t.test_files = FileList['**/*_test.rb']
end
