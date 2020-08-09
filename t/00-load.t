use 5.30.0;
use strict;
use warnings;
use Test::More;

plan tests => 2;

BEGIN {
    use_ok('Net::EtcDv2') || print "Bail out!\n";
    use_ok('Net::EtcDv2::EntryStat') || print "Bail out!\n";
}

diag("");
diag("Testing Net::EtcDv2 $Net::EtcDv2::VERSION, Perl $], $^X");
diag("Testing Net::EtcDv2::EntryStat $Net::EtcDv2::VERSION, Perl $], $^X");
