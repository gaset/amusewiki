package AmuseWikiFarm::Archive::Queue;
use utf8;
use strict;
use warnings;

use Moose;
use namespace::autoclean;

use JSON qw/to_json from_json/;
use DateTime;

=head2 site

The schema object.

=cut

has dbic => (
             isa => 'Object',
             is => 'ro',
             required => 1,
            );

sub bookbuilder_add {
    my ($self, $site_id, $payload) = @_;
    return $self->add_job(bookbuilder => $site_id, $payload, 3);
}

sub add_job {
    my ($self, $task, $site_id, $payload, $priority) = @_;
    my $insertion = {
                     site_id => $site_id,
                     task    => $task,
                     payload => to_json($payload),
                     status  => 'pending',
                     created => DateTime->now,
                     priority => $priority || 10,
                    };
    my $job = $self->dbic->resultset('Job')->create($insertion);
    return $job->id;
}

sub fetch_job_by_id {
    my ($self, $id) = @_;
    my $job = $self->dbic->resultset('Job')->find($id);
    return $job;
}

sub fetch_job_by_id_json {
    my ($self, $id) = @_;
    my $job = $self->fetch_job_by_id($id);
    return to_json({ errors => 'No such job' }) unless $job;
    # for now expose everything
    my $struct = {
                  id       => $id,
                  site_id  => $job->site_id,
                  task     => $job->task,
                  payload  => from_json($job->payload),
                  status   => $job->status,
                  created  => $job->created->iso8601,
                  # completed => $job->completed->iso8601,
                  priority => $job->priority,
                  produced => $job->produced,
                  errors   => $job->errors,
                 };
    return to_json($struct);
}

sub get_job {
    my $self = shift;
    my $job = $self->dbic->resultset('Job')->search({
                                                     status => 'pending',
                                                    },
                                                    {
                                                     order_by => [qw/priority
                                                                     created/],
                                                    })->first;
    return unless $job;
    $job->status('taken');
    $job->update;
    return $job;
}


__PACKAGE__->meta->make_immutable;

1;