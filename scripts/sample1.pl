use strict;
use warnings;
use utf8;

use AnyEvent;
use Coro;
use Coro::Timer;
use Coro::AnyEvent;
use AnyEvent::WebService::Lingr;
use Encode qw/encode_utf8/;
use Config::Pit;
use FindBin;
use Path::Class qw/file/;
use Log::Minimal;
use Try::Tiny;

my $lingr = AnyEvent::WebService::Lingr->new(
    %{ pit_get("lingr.com") },
    timeout => 100,
);
my $file = file($FindBin::Bin, "session");

async {

    if ( -e $file ) {
        $lingr->request("session/verify", session => $file->slurp, Coro::rouse_cb);
        my ($hdr, $json, $reason) = Coro::rouse_wait;

        try {
            check_response($hdr, $json, $reason);
            infof "session is verify";
        }
        catch {
            create_session();
        };
    }
    else {
        create_session();
    }

    $lingr->request("user/get_rooms", Coro::rouse_cb);
    my ($hdr, $json, $reason) = Coro::rouse_wait;

    check_response($hdr, $json, $reason);

    $lingr->request("room/subscribe", room => join (",", @{$json->{rooms}}), Coro::rouse_cb);
    ($hdr, $json, $reason) = Coro::rouse_wait;

    check_response($hdr, $json, $reason);

    my $counter = $json->{counter};
    while (1) {
        $lingr->request("event/observe", counter => $counter, Coro::rouse_cb);
        my ($hdr, $json, $reason) = Coro::rouse_wait;

        if ( $reason eq "Operation timed out" ) {
            warnf "timeout";
            next;
        }
        check_response($hdr, $json, $reason);

        for my $event (@{$json->{events}} ) {
            infof encode_utf8 $event->{message}{text} if $event->{message};
        }
        $counter = $json->{counter} if defined $json->{counter};
    }
};

AE::cv->recv;

sub create_session {
    $lingr->create_session(Coro::rouse_cb);
    my ($hdr, $json, $reason) = Coro::rouse_wait;

    check_response($hdr, $json, $reason);

    my $fh = $file->openw or croakf $!;
    $fh->print($json->{session});
    $fh->close;

    infof "create new session";
}

sub check_response {
    my ($hdr, $json, $reason) = @_;
    croakf Dumper($hdr, $reason) unless $json;
    croakf Dumper($hdr, $json->{code} . ":" . $json->{detail}) unless $json->{status} eq "ok";
}

