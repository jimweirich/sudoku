#!/usr/bin/env ruby

require 'set'

class Cell
  attr_reader :number, :groups

  def initialize(name="unamed")
    @name = name
    @groups = []
  end

  def number=(value)
    @number = value.nonzero?
  end

  def available_numbers
    return Set[] if number
    result = Set[*(1..9)]
    @groups.each do |g|    
      result -= g.numbers
    end
    result
  end

  def join(group)
    @groups << group
  end

  def to_s
    @name
  end

  def inspect
    to_s
  end
end

class Group
  def initialize
    @cells = []
  end

  def <<(cell)
    cell.join(self)
    @cells << cell
    self
  end

  def numbers
    Set[*@cells.map { |c| c.number }.compact]
  end
end

class Grid
  include Enumerable

  def initialize(verbose=nil)
    @verbose = verbose
    @cells = (0...81).map { |i|
      Cell.new("C#{i/9}#{i%9}")
    }
    define_groups
  end

  def parse(string)
    numbers = string.gsub(/^#.*$/, '').gsub(/\n/, '').
      split(//).map { |n| n.to_i }
    each do |cell|
      cell.number = numbers.shift
    end
    self
  end

  def each
    @cells.each do |cell|
      yield cell
    end
  end

  def solved?
    all? { |cell| cell.number }
  end

  def stuck?
    any? { |cell| cell.number.nil? && cell.available_numbers.size == 0 }
  end
  
  def to_s
    encoding.
      gsub(/.../, "\\0 ").
      gsub(/.{12}/, "\\0\n").
      gsub(/.{39}/m, "\\0\n").
      gsub(/[\d.]/, "\\0 ")
  end

  def inspect
    "<Grid #{encoding}>"
  end

  def encoding
    map { |cell| cell.number || "." }.join
  end

  def solve
    alternatives = []
    while true
      while solve_one_square
      end
      return if solved?
      if stuck?
        fail "No Solution Found" if alternatives.empty?
        puts "Backtracking (#{alternatives.size})" if @verbose
        guess(alternatives)
      else
        cell = find_candidate_for_guessing
        remember_alternatives(cell, alternatives)
        guess(alternatives)
      end
    end
  end

  private

  def solve_one_square
    each do |cell|
      an = cell.available_numbers
      if an.size == 1
        puts "Put #{an.to_a.first} at (#{cell})" if @verbose
        cell.number = an.to_a.first
        return true
      end
    end
    return false
  end
  
  def find_candidate_for_guessing
    cells_without_numbers.sort_by { |cell| 
      [cell.available_numbers.size, to_s]
    }.first
  end

  def cells_without_numbers
    to_a.reject { |cell| cell.number }
  end

  def remember_alternatives(cell, alternatives)
    cell.available_numbers.each do |n|
      alternatives.push([encoding, cell, n])
    end
  end
  
  def guess(alternatives)
    state, cell, number = alternatives.pop
    parse(state)
    puts "Guessing #{number} at #{cell}" if @verbose
    cell.number = number        
  end

  def define_groups
    define_columns
    define_rows
    define_blocks
  end

  def define_rows
    (0..8).each do |r|
      define_group(r..r, 0..8)
    end
  end

  def define_columns
    (0..8).each do |c|
      define_group(0..8, c..c)
    end
  end

  def define_blocks
    [(0..2), (3..5), (6..8)].each do |rrange|
      [(0..2), (3..5), (6..8)].each do |crange|
        define_group(rrange, crange)
      end
    end
  end

  def define_group(row_range, col_range)
    g = Group.new
    row_range.each do |r|
      col_range.each do |c|
        g << @cells[r*9 + c]
      end
    end
  end
  
end

if __FILE__ == $0 then
  def solve(string)
      grid = Grid.new(true).parse(string)
      puts grid
      
      grid.solve
      puts
      puts grid
      puts
  end

  if ARGV.empty?
    puts "Usage: ruby sudoku.rb sud-files..."
    exit 
  end

  ARGV.each do |fn|
    puts "Solving #{fn} ----------------------------------------------"
    open(fn) do |f|
      solve(f.read)
    end
  end
end
