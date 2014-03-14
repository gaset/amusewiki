package AmuseWikiFarm::Controller::Feed;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }

=head1 NAME

AmuseWikiFarm::Controller::Feed - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=head2 index

Path: /feed

RSS 2.0 feed, built using XML::FeedPP

=cut

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;
    my $site = $c->stash->{site};
    my @texts = $site->titles->latest;
    my $feed = $c->model('Feed');

    # set up the channel
    $feed->title($site->sitename);
    $feed->description($site->siteslogan);
    $feed->link($site->canonical);
    $feed->language($site->locale);

    $feed->xmlns('xmlns:atom' => "http://www.w3.org/2005/Atom");

    # set the link to ourself
    $feed->set('atom:link@href', $c->uri_for_action($c->action));
    $feed->set('atom:link@rel', 'self');
    $feed->set('atom:link@type', "application/rss+xml");

    if (@texts) {
        $feed->pubDate($texts[0]->pubdate->epoch);
    }

    foreach my $text (@texts) {
        my $link = $c->uri_for_action('/library/text', $text->uri);

        # here we must force stringification
        my $item = $feed->add_item("$link");
        $item->title($text->title);
        $item->pubDate($text->pubdate->epoch);
        $item->guid(undef, isPermaLink => 1);

        my @lines;
        foreach my $method (qw/author title subtitle notes source/) {
            my $string = $text->$method;
            if (length($string)) {
                push @lines,
                  '<strong>' . $c->loc(ucfirst($method)) . '</strong>: ' . $string;
            }
        }
        $item->description('<div>' . join('<br>', @lines) . '</div>');
    }

    # render and set
    $c->response->content_type('application/rss+xml');
    $c->response->body($feed->to_string);
}

=encoding utf8

=head1 AUTHOR

Marco,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;