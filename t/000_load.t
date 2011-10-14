#!perl -w
use strict;
use Test::More tests => 1;

BEGIN {
    use_ok 'AnyEvent::WebService::Lingr';
}

diag "Testing AnyEvent::WebService::Lingr/$AnyEvent::WebService::Lingr::VERSION";
