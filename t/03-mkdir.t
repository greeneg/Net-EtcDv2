use 5.30.0;
use strict;
use warnings;

use JSON;
use Test::More 'no_plan';
use Net::EtcDv2;

SKIP: {
    skip "missing env vars(ETCD_HOST, ETCD_PORT)", 2,
        unless (exists $ENV{'ETCD_HOST'} && exists $ENV{'ETCD_PORT'});

    # a little prettier debug output
    say STDERR "" if $ENV{DEBUG};
    my $o = Net::EtcDv2->new(
        'host' => $ENV{'ETCD_HOST'},
        'port' => $ENV{'ETCD_PORT'}
    );

    ok(defined $o);
    say STDERR "" if $ENV{DEBUG};
    my $r = $o->mkdir('/myTestDir');
    # now lets inspect the output
    my $content = decode_json($r);
    ok($content->{'node'}->{'key'} eq '/myTestDir');
}
