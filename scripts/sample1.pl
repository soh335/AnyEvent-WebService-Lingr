use strict;
use warnings;
use utf8;

use AnyEvent;
use Coro;
use Coro::AnyEvent;
use AnyEvent::WebService::Lingr;
use Encode qw/encode_utf8/;
use Config::Pit;
use FindBin;
use Path::Class qw/file/;

my $lingr = AnyEvent::WebService::Lingr->new(
    %{ pit_get("lingr.com") }
);
my $file = file($FindBin::Bin, "session");

async {

    if ( -e $file ) {
        $lingr->request("session/verify", session => $file->slurp, cb => Coro::rouse_cb);
        my $json = Coro::rouse_wait;

        if ( $json->{status} eq "ok" ) {
            $lingr->{session} = $json->{session};
            warn "session is verify";
        }
        elsif ( $json->{code} eq "invalid_session" ) {
            create_session();
        }
    }
    else {
        create_session();
    }

    $lingr->request("user/get_rooms", cb => Coro::rouse_cb);
    my $json = Coro::rouse_wait;

    check_json($json);

    $lingr->request("room/subscribe", room => join (",", @{$json->{rooms}}), cb => Coro::rouse_cb);
    $json = Coro::rouse_wait;

    check_json($json);

    my $counter = $json->{counter};
    while (1) {
        $lingr->request("event/observe", counter => $counter, cb => Coro::rouse_cb);
        my $res_json = Coro::rouse_wait;

        check_json($res_json);

        for my $event (@{$res_json->{events}} ) {
            warn encode_utf8 $event->{message}{text} if $event->{message};
        }
        $counter = $res_json->{counter} if defined $res_json->{counter};
    }
};

AE::cv->recv;

sub create_session {
    $lingr->session_create(Coro::rouse_cb);
    my $json = Coro::rouse_wait;

    check_json($json);

    my $fh =$file->openw or die $!;
    $fh->print($json->{session});
    $fh->close;

    warn "create new session";
}

sub check_json {
    my $json = shift;
    die $json->{code} . ":" . $json->{detail} unless $json->{status} eq "ok";
}

# callback style
#
#$lingr->request("user/get_rooms", cb => sub {
#        my $json = shift;
#        $lingr->request("room/subscribe", room => join (",", @{$json->{rooms}}), cb => sub {
#                $json = shift;
#
#                my $func; $func = sub {
#                    my $counter = shift;
#                    $lingr->request("event/observe", counter => $counter, cb => sub {
#                            my $_json = shift;
#                            for my $event (@{$_json->{events}} ) {
#                                warn encode_utf8 $event->{message}{text} if $event->{message};
#                            }
#                            $func->($_json->{counter} || $counter);
#                        });
#                };
#
#                $func->($json->{counter});
#            });
#    });
#
