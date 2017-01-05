use strict;
use warnings;
use 5.006; # Found with Perl::MinimumVersion

package Log::UDP::Client;

use Moose;
with 'Data::Serializable' => { -version => '0.40.0' };

# ABSTRACT: A simple way to send structured log messages via UDP

use IO::Socket::INET ();
use Carp qw(carp croak);

=attr server_address : Str

IP address or hostname for the server you want to send the messages to.
This field can be changed after instantiation. Default is 127.0.0.1.

=cut

has "server_address" => (
    is      => 'rw',
    isa     => 'Str',
    default => sub { "127.0.0.1"; },
);

=attr server_port : Int

Port for the server you plan to send the messages to.
This field can be changed after instantiation. Default is port 9999.

=cut

has "server_port" => (
    is      => 'rw',
    isa     => 'Int',
    default => sub { 9999; }
);

=attr throws_exception : Bool

If errors are encountered, should we throw exception or just return?
Default is return. Set to true for exceptions. You can change this flag
after instantiation.

=cut

has "throws_exception" => (
    is      => 'rw',
    isa     => 'Bool',
    default => 0,
);

=attr socket : IO::Socket::INET

Read-only field that contains the socket used to send the messages.

=cut

has "socket" => (
    is      => 'ro',
    isa     => 'IO::Socket::INET',
    lazy    => 1,
    default => sub { IO::Socket::INET->new( Proto => 'udp' ); }
);

=method send($message)

Instance method that actually encodes and transmits the specified message
over UDP to the listening server. Will die if throw_exception is set to true
and some kind of transmission error occurs. The message will be serialized by
the instance-defined serializer. Returns true on success.

=cut

# Perl::Critic bug: Subroutines::RequireArgUnpacking shouldn't be needed here
## no critic qw(Subroutines::ProhibitBuiltinHomonyms Subroutines::RequireArgUnpacking)
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
    if ( not $self->throws_exception and not defined($serialized_message) ) {
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
        croak($error) if $self->throws_exception;
        carp($error);
        return 0;
    }

    # Everything OK
    return 1;

}

1;

__END__

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

=head1 INHERITED METHODS

=for :list
* deserialize
* deserializer
* serialize
* serializer
* serializer_module

All of these methods are inherited from L<Data::Serializable>. Read more about them there.

=head1 SEE ALSO

=for :list
* L<Moose>
* L<Storable>
* L<JSON::XS>
* L<IO::Socket::INET>
