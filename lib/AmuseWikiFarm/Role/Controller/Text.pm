package AmuseWikiFarm::Role::Controller::Text;

use strict;
use warnings;

use MooseX::MethodAttributes::Role;
requires qw/base/;

use AmuseWikiFarm::Utils::Amuse qw//;
use HTML::Entities qw//;
use AmuseWikiFarm::Log::Contextual;

sub match :Chained('base') PathPart('') :CaptureArgs(1) {
    my ($self, $c, $arg) = @_;
    log_debug { "In match" };
    my $name = $arg;
    my $ext = '';
    my $append_ext = '';
    my $site = $c->stash->{site};

    # strip the extension
    if ($arg =~ m/(.+?) # name
                  \.   # dot
                  # and extensions we provide
                  (
                      a4\.pdf |
                      lt\.pdf |
                      sl\.tex |
                      sl\.pdf |
                      pdf     |
                      html    |
                      tex     |
                      epub    |
                      muse    |
                      zip     |

                      # these two need special treatment
                      jpe?g   |
                      png
                  )$
                 /x) {
        $name = $1;
        $ext  = $2;
    }

    log_debug { "Ext is $ext, name is $name" };

    if ($ext) {
        $append_ext = '.' . $ext;

        my %managed = $site->available_text_exts;
        if (exists $managed{$append_ext}) {
            unless ($managed{$append_ext}) {
                log_debug { "$ext is not provided" };
                $c->detach('/not_found');
            }
        }
    }

    # assert we are using canonical names.
    my $canonical = AmuseWikiFarm::Utils::Amuse::muse_naming_algo($name);
    log_debug { "canonical is $canonical" };

    # find the title or the attachment
    if (my $text = $c->stash->{texts_rs}->single({ uri => $canonical})) {
        $c->stash(text => $text);
        if ($canonical ne $name) {
            my $location = $c->uri_for($text->full_uri);
            $c->response->redirect($location, 301);
            $c->detach();
            return;
        }
        # static files are served here
        if ($ext) {
            log_debug { "Got $canonical $ext => " . $text->title };
            my $served_file = $text->filepath_for_ext($ext);
            if (-f $served_file) {
                $c->stash(serve_static_file => $served_file);
                $c->detach($c->view('StaticFile'));
                return;
            }
            else {
                # this should not happen
                log_warn { "File $served_file expected but not found!" };
                $c->detach('/not_found');
                return;
            }
        }
        $c->stash(page_title => HTML::Entities::decode_entities($text->title));

    }
    elsif (my $attach = $site->attachments->by_uri($canonical . $append_ext)) {
        log_debug { "Found attachment $canonical$append_ext" };
        if ($name ne $canonical) {
            log_warn { "Using $canonical instead of $name, shouldn't happen" };
        }
        $c->stash(serve_static_file => $attach->f_full_path_name);
        $c->detach($c->view('StaticFile'));
        return;
    }
    else {
        $c->stash(uri => $canonical);
        $c->detach('/not_found');
    }
}

sub text :Chained('match') :PathPart('') :Args(0) {
    my ($self, $c) = @_;
    log_debug { "In text" };
    my $text = $c->stash->{text} or die "WTF?";

    # we are in a role, so if we don't set this special/text.tt and
    # library/text.tt will be searched .
    $c->stash(template => 'text.tt',
              load_highlight => $c->stash->{site}->use_js_highlight);

    foreach my $listing (qw/authors topics/) {
        my @list;
        my $categories = $text->$listing;
        while (my $cat = $categories->next) {
            push @list, {
                         uri => $cat->full_uri,
                         name => $cat->name,
                        };
        }
        $c->stash("text_$listing" => \@list);
    }
    if ($c->stash->{blog_style} && $text->is_regular) {
        if (my $next_text = $text->newer_text) {
            $c->stash(text_next_uri => $next_text->full_uri);
        }
        if (my $prev_text = $text->older_text) {
            $c->stash(text_prev_uri => $prev_text->full_uri);
        }
    }
    my $meta_desc = '';
    if (my $teaser = $text->teaser) {
        $meta_desc = $teaser;
    }
    else {
      TEXTFIELD:
        foreach my $method (qw/author title subtitle date notes/) {
            if (my $info = $text->$method) {
                $meta_desc .= $info . " ";
            }
            last TEXTFIELD if length($meta_desc) > 160;
        }
    }
    $c->stash(meta_description => $meta_desc);
    $c->response->headers->last_modified($text->f_timestamp_epoch || time());
}

sub edit :Chained('match') PathPart('edit') :Args(0) {
    my ($self, $c) = @_;
    log_debug { "In edit" };
    my $text = $c->stash->{text};
    $c->response->redirect($c->uri_for_action('/edit/revs', [$text->f_class,
                                                             $text->uri]));
}

1;
