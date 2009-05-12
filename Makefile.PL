use inc::Module::Install 0.87;

name     'Log-UDP-Client';
all_from 'lib/Log/UDP/Client.pm';
author   'Robin Smidsrød <robin@smidsrod.no>';
license  'perl';

requires 'Moose'              => 0;
requires 'IO::Socket::INET'   => 0;
requires 'Carp'               => 0;
requires 'Data::Serializable' => 0;

test_requires 'Test::More'    => 0;
test_requires 'JSON'          => 0;
test_requires 'Time::HiRes'   => 0;

WriteAll;
