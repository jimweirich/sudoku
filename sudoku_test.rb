require 'rubygems'
require 'test/unit'
require 'shoulda'

require 'sudoku'


class CellTest < Test::Unit::TestCase
  def create_group_with(cell, *numbers)
    g = Group.new
    g << cell
    numbers.each do |n|
      c = Cell.new(0,0)
      c.number = n
      g << c
    end
    g
  end

  context 'a cell' do
    setup do
      @cell = Cell.new(2,5)
    end

    should 'knows its location' do
      assert_equal 2, @cell.row
      assert_equal 5, @cell.col
    end

    should 'know its name' do
      assert_equal "C25", @cell.to_s
    end

    should 'initially have no number' do
      assert_nil @cell.number
    end

    should 'be able to set number' do
      @cell.number = 4
      assert_equal 4, @cell.number
    end

    should 'accept a zero as no number' do
      @cell.number = 0
      assert_nil @cell.number
    end

    should 'report all possible numbers available' do
      assert_equal( Set[*(1..9)], @cell.available_numbers )
    end

    context 'within a group' do
      setup do
        @group = create_group_with(@cell, 3, 4, 5)
      end

      should 'be know about its group' do
        @cell.groups.include?(@group)
      end

      should 'report available numbers not in the group' do
        assert_equal Set[1, 2, 6, 7, 8, 9], @cell.available_numbers
      end

      should 'report no available numbers if a number has been assigned' do
        @cell.number = 6
        assert_equal Set[], @cell.available_numbers
      end

    end
  end
end


class GroupTest < Test::Unit::TestCase
  context 'a group of cells' do
    setup do
      @group = Group.new
    end
    
    should 'exist' do
      assert_not_nil @group
    end

    context 'with cells' do
      setup do
        @cells = (1..10).map { |i| Cell.new(0, i) }
        @cells.each do |c| @group << c end
      end

      should 'give a list of numbers' do
        assert_equal Set[], @group.numbers
      end

      context 'with some numbers' do
        setup do
          @cells[0].number = 3
          @cells[3].number = 6
        end

        should 'give a list of the remaining missing numbers' do
          assert_equal [3, 6], @group.numbers.sort
        end
      end

    end

  end
end


class GridTest < Test::Unit::TestCase
  context 'a grid' do
    setup do
      @grid = Grid.new
    end

    should 'give all 9 numbers for any cell' do
      assert_equal((1..9).to_a, @grid[0,0].available_numbers.sort)
      assert_equal((1..9).to_a, @grid[8,8].available_numbers.sort)
      assert_equal((1..9).to_a, @grid[2,6].available_numbers.sort)
    end

    should 'wire up the groups' do
      (0..8).each do |i| @grid[0,i].number = i+1 end
      assert_equal 0, @grid[0,0].available_numbers.size
      assert_equal 6, @grid[1,0].available_numbers.size
      assert_equal 8, @grid[3,0].available_numbers.size
    end

    should 'solve the Wikipedia Puzzle' do
      puzzle =
        "53  7    " +
        "6  195   " +
        " 98    6 " +
        "8   6   3" +
        "4  8 3  1" +
        "7   2   6" +
        " 6    28 " +
        "   419  5" +
        "    8  79"
      grid = Grid.new.parse(puzzle)
      grid.solve
      assert_equal "534678912672195348198342567" +
        "859761423426853791713924856" +
        "961537284287419635345286179",
        grid.number_string      
    end

    should 'solve the Medium Puzzle' do
      puzzle =
        " 4   7 3 " +
        "  85  1  " +
        " 15 3  9 " +
        "5   7 21 " +
        "  6   8  " +
        " 81 6   9" +
        " 2  4 57 " +
        "  7  29  " +
        " 5 7   8 "
      grid = Grid.new.parse(puzzle)
      grid.solve
      assert_equal "942187635368594127715236498" +
        "593478216476921853281365749" +
        "829643571137852964654719382",
        grid.number_string      
    end

    should 'solve the Evil Puzzle' do
      puzzle =
        "  53 694 " +
        " 3 1    6" +
        "       3 " +
        "7  9     " +
        " 1  3  2 " +
        "     2  7" +
        " 6       " +
        "8    7 5 " +
        " 436 81  "

      grid = Grid.new.parse(puzzle)
      grid.solve
      assert_equal "285376941439125786176849235" +
        "752981364618734529394562817" +
        "567213498821497653943658172",
        grid.number_string      
    end

  end
end
