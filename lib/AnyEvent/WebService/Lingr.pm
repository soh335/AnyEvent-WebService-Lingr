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

sub session_create {
    my ($self, $cb) = @_;

    my %param = ( user => $self->{user}, password => $self->{password} );
    $param{app_key} = $self->{app_key} if defined $self->{app_key};

    my $method = "session/create";
    my $req = $self->_get_req($BASE_URL . "/$method", $METHODS{$method}, \%param);
    $self->_do_request($METHODS{$method}, $req, sub {
        my $json = shift;
        $self->{session} = $json->{session};
        $cb->($json);
    });
}

sub request {
    my ($self, $method, %args) = @_;
    croak "not defined method" unless defined $METHODS{$method};
    my $cb = delete $args{cb};
    $args{session} ||= $self->{session};

    my $url = ( $method ne "event/observe" ? $BASE_URL : $OBSERVE_URL ) . "/$method";

    my $req = $self->_get_req($url, $METHODS{$method}, \%args);
    $self->_do_request($METHODS{$method}, $req, $cb);
}

sub _get_req {
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
    http_request $method => $req->uri, body => $req->content, headers => \%headers, sub {
        my ($body, $hdr) = @_;
        my $json = decode_json($body);
        $cb->($json);
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
