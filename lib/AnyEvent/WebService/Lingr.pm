package AnyEvent::WebService::Lingr;
use 5.008_001;
use strict;
use warnings;

our $VERSION = '0.01';

use AnyEvent;
use AnyEvent::HTTP;
use HTTP::Request::Common;
use URI;
use Carp;
use JSON;

our $BASE_URL = "http://lingr.com/api";
our $OBSERVE_URL = "http://lingr.com:8080/api";
our %METHODS = (
    "session/create"    => "POST",
    "session/verify"    => "GET",
    "session/destroy"   => "POST",
    "room/show"         => "GET",
    "room/get_archives" => "GET",
    "room/subscribe"    => "POST",
    "room/unsubscribe"  => "POST",
    "room/say"          => "POST",
    "user/get_rooms"    => "GET",
    "event/observe"     => "GET",
);

sub new {
    my ($class, %args) = @_;

    croak "missing require parameter 'user" unless defined $args{user};
    croak "missing require parameter 'passowrd" unless defined $args{password};

    bless \%args, $class;
}

sub create_session {
    my ($self, $cb) = @_;

    my %param = ( user => $self->{user}, password => $self->{password} );
    $param{app_key} = $self->{app_key} if defined $self->{app_key};

    $self->request("session/create", %param, sub {
        my ($hdr, $json, $reason) = @_;

        $self->{session} = $session if defined $json and $json->{status} eq "ok";

        $cb->($hdr, $json, $reason);
    });
}

sub destroy_session {
    my ($self, $cb) = @_;

    $self->request("session/destroy", sub {
        my ($hdr, $json, $reason) = @_;

        $self->{session} = undef if defined $json and $json->{status} eq "ok";

        $cb->($hdr, $json, $reason);
    });
}

sub verify_session {
    my ($self, $session, $cb) = @_;

    $self->request("session/verify", session => $session, sub {
        my ($hdr, $json, $reason) = @_;

        $self->{session} = $session if defined $json and $json->{status} eq "ok";

        $cb->($hdr, $json, $reason);
    });
}

sub request {
    my $cb = pop;

    my ($self, $method, %args) = @_;
    croak "not defined method" unless defined $METHODS{$method};
    $args{session} ||= $self->{session} if $self->{session};

    my $url = ( $method ne "event/observe" ? $BASE_URL : $OBSERVE_URL ) . "/$method";

    my $req = $self->_gen_request($url, $METHODS{$method}, \%args);
    $self->_do_request($METHODS{$method}, $req, $cb);
}

sub _gen_request {
    my ($self, $url, $method, $param) = @_;

    if ( $method eq "GET" ) {
        my $uri = URI->new($url);
        $uri->query_form( %$param );

        return GET $uri;
    }
    elsif ( $method eq "POST" ) {
        return POST $url, [%$param];
    }
}

sub _do_request {
    my ($self, $method, $req, $cb) = @_;

    my %headers = map { $_ => $req->header($_), } $req->headers->header_field_names;

    my %params = (
        body => $req->content,
        headers => \%headers,
    );

    $params{timeout} = $self->{timeout} if defined $self->{timeout};

    http_request $method => $req->uri, %params, sub {
        my ($body, $hdr) = @_;
        if ( $hdr->{Status} =~ /^2/ ) {
            local $@;
            my $json = eval { decode_json($body) };
            $cb->($hdr, $json, $@ ? "parse error: $@" : $hdr->{Reason});
        }
        else {
            $cb->($hdr, undef, $hdr->{Reason});
        }
    };
}

1;
__END__

=head1 NAME

AnyEvent::WebService::Lingr - Perl extention to do something

=head1 VERSION

This document describes AnyEvent::WebService::Lingr version 0.01.

=head1 SYNOPSIS

    use AnyEvent::WebService::Lingr;

=head1 DESCRIPTION

# TODO

=head1 INTERFACE

=head2 Functions

=head3 C<< hello() >>

# TODO

=head1 DEPENDENCIES

Perl 5.8.1 or later.

=head1 BUGS

All complex software has bugs lurking in it, and this module is no
exception. If you find a bug please either email me, or add the bug
to cpan-RT.

=head1 SEE ALSO

L<perl>

=head1 AUTHOR

<<YOUR NAME HERE>> E<lt><<YOUR EMAIL ADDRESS HERE>>E<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2011, <<YOUR NAME HERE>>. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
