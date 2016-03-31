#!perl

use strict;
use warnings;
use utf8;
use Test::More tests => 6;
BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };

my $builder = Test::More->builder;
binmode $builder->output,         ":encoding(utf-8)";
binmode $builder->failure_output, ":encoding(utf-8)";
binmode $builder->todo_output,    ":encoding(utf-8)";
binmode STDOUT, ":encoding(utf-8)";


use AmuseWikiFarm::Schema;
use File::Spec::Functions qw/catfile catdir/;
use lib catdir(qw/t lib/);
use AmuseWiki::Tests qw/create_site/;
use Text::Amuse::Compile::Utils qw/write_file read_file/;
use Path::Tiny;
use JSON;
use Data::Dumper;
use AmuseWikiFarm::Utils::LexiconMigration;

my $schema = AmuseWikiFarm::Schema->connect('amuse');
my $id = '0lexicon0';
my $site = create_site($schema, '0lexicon0');

my $lexdir = path($site->path_for_site_files);

unless (-d $lexdir) {
    $lexdir->mkpath;
}

my $json = "lasdlkflk asdlkfj alksd garbage";

write_file($site->lexicon_file, $json);
# lazy build
is ($site->lexicon, undef);



$site = $schema->resultset('Site')->find($id);
write_file($site->lexicon_file, to_json({
                                         test => { it => 'Prova' },
                                         '<test>' => { it => '<Test>' },
                                         'test [_1] [_2] [_3]' => { it => '[_1] [_2] [_3] prova " ć100' },
                                        }));

is ($site->lexicon_translate(it => 'test'), 'Prova');
is ($site->lexicon_translate(it => '<test>'), '<Test>');
is ($site->lexicon_translate(it => '&lt;test&gt;'), undef);
is ($site->lexicon_translate(it => 'test [_1] [_2] [_3]', qw/uno due tre/),
    "uno due tre prova \" ć100");

use AmuseWikiFarm::Utils::LexiconMigration;
my $temp = Path::Tiny->tempdir;
foreach my $po (AmuseWikiFarm::Utils::LexiconMigration::convert($site->lexicon, $temp)) {
    diag "$po";
    my $po_body = read_file($po);
    diag $po_body;
    like $po_body, qr{%1 %2 %3 prova \\" ć100};
}
