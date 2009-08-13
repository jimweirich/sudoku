use integer;
@A = split //, <>;

sub R {
    for $i ( 0 .. 80 ) {
        next if $A[$i];
        my %t = map {
                 $_ / 9 == $i / 9
              || $_ % 9 == $i % 9
              || $_ / 27 == $i / 27 && $_ % 9 / 3 == $i % 9 / 3
              ? $A[$_]
              : 0 => 1
        } 0 .. 80;
        R( $A[$i] = $_ ) for grep { !$t{$_} } 1 .. 9;
        return $A[$i] = 0;
    }
    die @A;
}
R
