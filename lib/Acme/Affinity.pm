package Acme::Affinity;

# ABSTRACT: Compute the affinity between two people

our $VERSION = '0.0109';

use Moo;
use strictures 2;
use namespace::clean;

use Math::BigRat;

=head1 SYNOPSIS

  use Acme::Affinity;

  # Please see the documentation for the contents of these values
  my %arguments = (questions => [], importance => {}, me => [], you => []);

  my $affinity = Acme::Affinity->new(%arguments);

  my $score = $affinity->score;

=head1 DESCRIPTION

An C<Acme::Affinity> object computes the relationship affinity between two
people based on a common list of questions, answers and their weighted
importance.

=head1 ATTRIBUTES

=head2 questions

This is a list of hash references with question keys and answer array
references.

Example:

  [
    { 'how messy are you' => [ 'very messy', 'average', 'very organized' ] },
    { 'do you like to be the center of attention' => [ 'yes', 'no' ] },
  ]

=cut

has questions => (
    is      => 'ro',
    isa     => sub { die 'Not an ArrayRef' unless ref($_[0]) eq 'ARRAY' },
    default => sub { [] },
);

=head2 importance

This is a hash reference with importance level keys and weight values.

Default:

  {
    'irrelevant'         => 0,
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

This is an array reference triple of question responses, desired
responses and importance levels of person A for each of the given
B<questions>.

Example:

  #   Person A           Person B           Importance
  [ [ 'very organized',  'very organized',  'very important' ],
    [ 'no',              'no',              'a little important' ], ]

So person A ("me") considers themself to be very organized, desires a
very organized person, and this is a very important to them.

Person A also does not need to be the center of attention, desires the
same type of person, but this is only a little important.

=cut

has me => (
    is      => 'ro',
    isa     => sub { die 'Not an ArrayRef' unless ref($_[0]) eq 'ARRAY' },
    default => sub { [] },
);

=head2 you

This is an array reference triple of question responses, desired
responses and importance levels of person B for each of the given
B<questions>.

Example:

  #   Person B           Person A    Importance
  [ [ 'very organized',  'average',  'a little important' ],
    [ 'yes',             'no',       'somewhat important' ], ]

Person B considers themself to be very organized, but only desires
someone who is average, and this is only a little important to them.

Person B likes to be the center of attention, desires someone who does
not, and this is somewhat important.

=cut

has you => (
    is      => 'ro',
    isa     => sub { die 'Not an ArrayRef' unless ref($_[0]) eq 'ARRAY' },
    default => sub { [] },
);

=head1 METHODS

=head2 new

  my $affinity = Acme::Affinity->new(
    questions  => \@questions,
    importance => \%importance,
    me         => \@me,
    you        => \@you,
  );

Create a new C<Acme::Affinity> object.

=head2 score

  my $score = $affinity->score;

Compute the affinity score for the two given people.

=cut

sub score {
    my $self = shift;

    my $me_score  = _score( $self->me, $self->you, $self->importance );
    my $you_score = _score( $self->you, $self->me, $self->importance );

    my $m = Math::BigRat->new($me_score);
    my $y = Math::BigRat->new($you_score);

    my $question_count = Math::BigRat->new( scalar @{ $self->me } );

    my $product = $m->bmul($y);

    my $score = $product->broot($question_count);

    return $score->numify * 100;
}

sub _score {
    my ( $me, $you, $importance ) = @_;

    my $score = 0;
    my $total = 0;

    for my $i ( 0 .. @$me - 1 ) {
        $total += $importance->{ $me->[$i][2] };

        if ( $me->[$i][1] eq $you->[$i][0] ) {
            $score += $importance->{ $me->[$i][2] };
        }
    }

    $score /= $total
        if $total != 0;

    return $score;
}

1;
__END__

=head1 SEE ALSO

The F<eg/*> and F<t/01-methods.t> programs in this distribution.

L<Moo>

L<Math::BigRat>

L<https://www.youtube.com/watch?v=m9PiPlRuy6E>

=cut
