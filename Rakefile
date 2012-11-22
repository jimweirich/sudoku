#!/usr/bin/env ruby

require 'rake/clean'
require 'rake/testtask'

CLOBBER.include("coverage")

task :default => :specs

task :specs do
  sh "rspec sudoku_spec.rb"
end
