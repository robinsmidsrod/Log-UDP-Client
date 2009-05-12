package Log::UDP::Client;
use Moose;

with 'Data::Serializable';

use IO::Socket::INET ();
use Carp qw(croak confess);

=head1 NAME

Log::UDP::Client - a simple way to send structured log messages via UDP

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

    use Log::UDP::Client;

    # Send the simple scalar to the server
    Log::UDP::Client->new->send("Hi");
    
    # Log lots of messages
    my $logger = Log::UDP::Client->new(server_port => 15000);
    my $counter=0;
    while(++$counter) {
        $logger->send($counter);
        last if $counter >= 1000;
    }
    
    # Send some debugging info
    $logger->send({
        pid     => $$,
        program => $0,
        args    => \@ARGV,
    });
    
    # Use of JSON serializer
    my $logger = Log::UDP::Client->new( serializer_module => 'JSON' );
    
    # Will emit { "message" => "Hi" } because JSON want to wrap stuff into a hashref
    $logger->send("Hi");
    
    # Use of custom serializer
    use Storable qw(freeze);
    my $logger = Log::UDP::Client->new (
        serializer => sub {
            return nfreeze( \( $_[0] ) );
        },
    );

=head1 DESCRIPTION

This module enables you to send a message (simple string or complicated object)
over an UDP socket to a listening server. The message will be encoded with a
serializer module (default is L<Storable>).

=head1 EXPORT

This is an object-oriented module. It has no exports.

=head1 ATTRIBUTES

=head2 server_address

IP address or hostname for the server you want to send the messages to.
This field can be changed after instantiation. Default is 127.0.0.1.

=cut

has "server_address" => (
    is      => 'rw',
    isa     => 'Str',
    default => sub { "127.0.0.1"; },
);

=head2 server_port

Port for the server you plan to send the messages to.
This field can be changed after instantiation. Default is port 9999.

=cut

has "server_port" => (
    is      => 'rw',
    isa     => 'Int',
    default => sub { 9999; }
);

=head2 throws_exception

If errors are encountered, should we throw exception or just return?
Default is return. Set to true for exceptions. You can change this flag
after instantiation.

=cut

has "throws_exception" => (
    is      => 'rw',
    isa     => 'Bool',
    default => 0,
);

=head2 socket

Read-only field that contains the socket used to send the messages.

=cut

has "socket" => (
    is      => 'ro',
    isa     => 'IO::Socket::INET',
    lazy    => 1,
    default => sub { IO::Socket::INET->new( Proto => 'udp' ); }
);

=head2 send

Instance method that actually encodes and transmits the specified message
over UDP to the listening server. Will die if throw_exception is set to true
and some kind of transmission error occurs. The message will be serialized by
the instance-defined serializer. Returns true on success.

=cut

sub send {
    my ($self, $message) = @_;

    # Make sure message was specified
    if ( @_ < 2 ) {
        croak("Please specify message") if $self->throws_exception;
        return; # FAIL
    }

    # Use the specified serializer to encode the message in a binary format
    my $serialized_message = $self->serialize( $message );

    # Trap failure in serialization when not emitting exceptions
    if ( ! $self->throws_exception and ! defined($serialized_message) ) {
        return; # FAIL
    }
    
    # Send UDP message
    my $length = CORE::send(
        $self->socket,
        $serialized_message,
        0,
        IO::Socket::INET::pack_sockaddr_in(
            $self->server_port,
            IO::Socket::INET::inet_aton( $self->server_address )
        )
    );

    # Check for transmission error
    if ( $length != length($serialized_message) ) {
        my $error = "Couldn't send message: $!\n";
        die($error) if $self->throws_exception;
        warn($error);
        return 0;
    }

    # Everything OK
    return 1;

}

=head1 INHERITED METHODS

=over

=item deserialize

=item deserializer

=item serialize

=item serializer

=item serializer_module

=back

All of these methods are inherited from L<Data::Serializable>. Read more about them there.

=cut

=head1 AUTHOR

Robin Smidsrød, C<< <robin at smidsrod.no> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-log-udp at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Log-UDP-Client>.
I will be notified, and then you'll automatically be notified of progress on your bug
as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Log::UDP::Client

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Log-UDP-Client>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Log-UDP-Client>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Log-UDP-Client>

=item * Search CPAN

L<http://search.cpan.org/dist/Log-UDP-Client/>

=back

=head1 SEE ALSO

L<Moose>, L<Storable>, L<JSON::XS>, L<IO::Socket::INET>

=head1 COPYRIGHT & LICENSE

Copyright 2009 Robin Smidsrød.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Log::UDP::Client
