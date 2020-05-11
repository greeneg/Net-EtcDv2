use 5.30.0;
use strict;
use warnings;
use Test::More 'no_plan';

BEGIN {
    use_ok('Net::EtcDv2');
}

SKIP: {
    skip "missing env vars(ETCD_HOST, ETCD_PORT)", 3,
        unless (exists $ENV{'ETCD_HOST'} && exists $ENV{'ETCD_PORT'});

    # a little prettier debug output
    say STDERR "" if $ENV{DEBUG};
    my $o = Net::EtcDv2->new(
        'host' => $ENV{'ETCD_HOST'},
        'port' => $ENV{'ETCD_PORT'}
    );
    my $r = $o->stat('/');

    ok(defined $r);
    ok($r->{'type'} eq 'dir');
    ok($r->{'ace'}  eq "*:POST, GET, OPTIONS, PUT, DELETE");
}