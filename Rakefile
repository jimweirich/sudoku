#!/usr/bin/env ruby

require 'rake/clean'
require 'rake/testtask'

CLOBBER.include("coverage")

task :default => :specs

task :specs, [:flags] do |t, args|
  sh "rspec sudoku_spec.rb #{args.flags}"
end

task :solve, [:puzzle] do |t, args|
  fail "Provide puzzle name" if args.puzzle.nil?
  sh "ruby sudoku.rb puzzles/#{args.puzzle}.sud"
end
