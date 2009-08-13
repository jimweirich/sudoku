#!/usr/bin/env ruby19

def r
  (0..80).each { |i|
    next if A[i] > 0
    ((1..9).to_a - (0..80).map { |j|
      (j/9 == i/9 ||
        j%9 == i%9 ||
        j/27 == i/27 && j%9/3 == i%9/3) ? A[j] : 0
    }).each { |g|
      A[i] = g
      r
      A[i] = 0
    }
    return
  }
  puts A.join
  exit
end
A = gets.strip.split(//).map {|n| n.to_i }
r
