use 5.30.0;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Net::EtcDv2' ) || print "Bail out!\n";
}

diag( "Testing Net::EtcDv2 $Net::EtcDv2::VERSION, Perl $], $^X" );
