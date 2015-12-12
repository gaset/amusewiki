#!/usr/bin/env perl

use utf8;
use strict;
use warnings;
use lib 'lib';
use AmuseWikiFarm::Schema;
use Crypt::XkcdPassword;

my $schema = AmuseWikiFarm::Schema->connect('amuse');

my ($username, $password) = @ARGV;
$password ||= Crypt::XkcdPassword->new(words => 'IT')->make_password(5, qr{\A[0-9a-zA-Z]{3,}\z});

die "Usage: $0 <username> [<password>]\n" unless $username && $password;

if (my $user = $schema->resultset('User')->find({ username => $username })) {
    $user->password($password);
    $user->update;
    print qq{Password for $username is now '$password'\n};
}
else {
    die "No such user $username!";
}


