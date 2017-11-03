package Acme::Affinity;

# ABSTRACT: Compute the affinity between two people

our $VERSION = '0.0101';

use Moo;
use strictures 2;
use namespace::clean;

use Math::BigRat;

=head1 SYNOPSIS

  use Acme::Affinity;
  my %arguments = ( questions => [], importance => [], me => [], you => [] );
  my $affinity = Acme::Affinity->new(%arguments);
  my $score = $affinity->score();

=head1 DESCRIPTION

An C<Acme::Affinity> object computes the affinity between two people based on a common list of questions and answers
and their weighted importance.

=head1 ATTRIBUTES

=head2 questions

A list of hash references with question keys and answer array references.

Example:

  [ { 'how messy are you' => [ 'very messy', 'average', 'very organized' ] },
    { 'do you like to be the center of attention' => [ 'yes', 'no' ] },
  ]

=cut

has questions => (
    is      => 'ro',
    isa     => sub { die 'Not an ArrayRef' unless ref($_[0]) eq 'ARRAY' },
    default => sub { [] },
);

=head2 importance

A hash reference with importance level keys and weight values.

Example:

  { 'irrelevant'         => 0,
    'a little important' => 1,
    'somewhat important' => 10,
    'very important'     => 50,
    'mandatory'          => 250,
  }

=cut

has importance => (
    is      => 'ro',
    isa     => sub { die 'Not a HashRef' unless ref($_[0]) eq 'HASH' },
    default => sub {
        {
            'irrelevant'         => 0,
            'a little important' => 1,
            'somewhat important' => 10,
            'very important'     => 50,
            'mandatory'          => 250,
        }
    },
);

=head2 me

An array reference triple of question responses, desired responses and importance levels for person A.

Example:

  [ # Me                You               Importance
    [ 'very organized', 'very organized', 'very important' ],
    [ 'no',             'no',             'a little important' ],
  ]

=cut

has me => (
    is      => 'ro',
    isa     => sub { die 'Not an ArrayRef' unless ref($_[0]) eq 'ARRAY' },
    default => sub { [] },
);

=head2 you

An array reference triple of question responses, desired responses and importance levels for person B.

Example:

  [ [ 'very organized', 'average', 'a little important' ],
    [ 'yes',            'no',      'somewhat important' ],
  ]

=cut

has you => (
    is      => 'ro',
    isa     => sub { die 'Not an ArrayRef' unless ref($_[0]) eq 'ARRAY' },
    default => sub { [] },
);

=head1 METHODS

=head2 new()

  my $affinity = Acme::Affinity->new(%arguments);

Create a new C<Acme::Affinity> object.

=head2 score()

  my $score = $affinity->score();

Compute the affinity score for the two given people.

=cut

sub score {
    my $self = shift;

    my $me = $self->me;
    my $you = $self->you;
    my $importance = $self->importance;

    my $me_score  = _score( $me, $you, $importance );
    my $you_score = _score( $you, $me, $importance );;

    my $m = Math::BigRat->new($me_score);
    my $y = Math::BigRat->new($you_score);

    my $question_count = Math::BigRat->new( scalar @$me );

    my $product = $m->bmul($y);

    my $score = $product->broot($question_count);

    return $score * 100;
}

sub _score {
    my ( $me, $you, $importance ) = @_;

    my $me_score = 0;
    my $me_total = 0;
    for my $i ( 0 .. @$me - 1 ) {
        $me_total += $importance->{ $me->[$i][2] };
        if ( $me->[$i][1] eq $you->[$i][0] ) {
            $me_score += $importance->{ $me->[$i][2] };
        }
    }
    $me_score /= $me_total;

    return $me_score;
}

1;
__END__

=head1 SEE ALSO

L<Moo>

L<https://www.youtube.com/watch?v=m9PiPlRuy6E>

=cut
