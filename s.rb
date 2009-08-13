#!/usr/bin/env ruby

def r
  (0..80).each do |i|
    next if A[i] > 0
    t = {}
    bad = (0..80).map { |j|
      (j/9 == i/9 ||
        j%9 == i%9 ||
        j/27 == i/27 && j%9/3 == i%9/3) ? A[j] : 0
    }.uniq
    guesses = ((1..9).to_a - bad)
    guesses.each do |g|
      A[i] = g
      r
      A[i] = 0
    end
    return
  end
  puts A.join('').scan(/.{9}/)
  exit
end
A = gets.strip.split(//).map {|n| n.to_i }
r
