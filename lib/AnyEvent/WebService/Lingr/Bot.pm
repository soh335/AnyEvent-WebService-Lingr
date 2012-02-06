package AnyEvent::WebService::Lingr::Bot;
use 5.008_001;
use strict;
use warnings;

our $VERSION = '0.01';

use AnyEvent;
use AnyEvent::WebService::Lingr;
use Digest::SHA qw/sha1_hex/;
use Carp;

sub new {
    my ($class, %args) = @_;

    my $room = $args{room} or croak "missing require parameter 'room'";
    my $bot_secret = $args{bot_secret} or croak "missing require parameter 'bot_secret'";
    my $bot = $args{bot} or croak "missing require parameter 'bot'";

    bless {
        room         => $room,
        bot          => $bot,
        bot_verifier => sha1_hex($bot . $bot_secret),
    }, $class;
}

sub say {
    my ($self, $text, $cb) = @_;

    my $req = AnyEvent::WebService::Lingr->_gen_request(
        $AnyEvent::WebService::Lingr::BASE_URI . "/room/say",
        "POST",
        {
            room          => $self->{room},
            bot           => $self->{bot},
            text          => $text,
            bot_verifier  => $self->{bot_verifier},
        }
    );
    AnyEvent::WebService::Lingr->_do_request($req, $cb);
}

1;
__END__

=head1 NAME

AnyEvent::WebService::Lingr::Bot - Perl extention to do something

=head1 VERSION

This document describes AnyEvent::WebService::Lingr::Bot version 0.01.

=head1 SYNOPSIS

    use AnyEvent::WebService::Lingr::Bot;

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
