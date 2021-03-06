package MooseX::Traits;
use Moose::Role;

use MooseX::Traits::Util qw(new_class_with_traits);

use warnings;
use warnings::register;

use namespace::autoclean;

our $VERSION   = '0.10';
our $AUTHORITY = 'id:JROCKWAY';

has '_trait_namespace' => (
    # no accessors or init_arg
    init_arg => undef,
    isa      => 'Str',
    is       => 'bare',
);

sub with_traits {
    my ($class, @traits) = @_;

    my $new_class = new_class_with_traits(
        $class,
        @traits,
    );

    return $new_class->name;
}

# somewhat deprecated, but use if you want to
sub new_with_traits {
    my $class = shift;

    my ($hashref, %args) = 0;
    if (ref($_[0]) eq 'HASH') {
        %args    = %{ +shift };
        $hashref = 1;
    } else {
        %args    = @_;
    }

    my $traits = delete $args{traits} || [];

    my $new_class = $class->with_traits(ref $traits ? @$traits : $traits );

    my $constructor = $new_class->meta->constructor_name;
    confess "$class ($new_class) does not have a constructor defined via the MOP?"
      if !$constructor;

    return $new_class->$constructor($hashref ? \%args : %args);

}

# this code is broken and should never have been added.  i probably
# won't delete it, but it is definitely not up-to-date with respect to
# other features, and never will be.
#
# runtime role application is fundamentally broken.  if you really
# need it, write it yourself, but consider applying the roles before
# you create an instance.

sub apply_traits {
    my ($self, $traits, $rebless_params) = @_;

    # disable this warning with "use MooseX::Traits; no warnings 'MooseX::Traits'"
    warnings::warnif('apply_traits is deprecated due to being fundamentally broken. '.
                     q{disable this warning with "no warnings 'MooseX::Traits'"});

    # arrayify
    my @traits = $traits;
    @traits = @$traits if ref $traits;

    if (@traits) {
        @traits = MooseX::Traits::Util::resolve_traits(
            $self, @traits,
        );

        for my $trait (@traits){
            $trait->meta->apply($self, rebless_params => $rebless_params || {});
        }
    }
}

no Moose::Role;

1;

__END__

=head1 NAME

MooseX::Traits - automatically apply roles at object creation time

=head1 SYNOPSIS

Given some roles:

  package Role;
  use Moose::Role;
  has foo => ( is => 'ro', isa => 'Int' required => 1 );

And a class:

  package Class;
  use Moose;
  with 'MooseX::Traits';

Apply the roles to the class at C<new> time:

  my $class = Class->with_traits('Role')->new( foo => 42 );

Then use your customized class:

  $class->isa('Class'); # true
  $class->does('Role'); # true
  $class->foo; # 42

=head1 DESCRIPTION

Often you want to create components that can be added to a class
arbitrarily.  This module makes it easy for the end user to use these
components.  Instead of requiring the user to create a named class
with the desired roles applied, or apply roles to the instance
one-by-one, he can just create a new class from yours with
C<with_traits>, and then instantiate that.

There is also C<new_with_traits>, which exists for compatability
reasons.  It accepts a C<traits> parameter, creates a new class with
those traits, and then insantiates it.

   Class->new_with_traits( traits => [qw/Foo Bar/], foo => 42, bar => 1 )

returns exactly the same object as

   Class->with_traits(qw/Foo Bar/)->new( foo => 42, bar => 1 )

would.  But you can also store the result of C<with_traits>, and call
other methods:

   my $c = Class->with_traits(qw/Foo Bar/);
   $c->new( foo => 42 );
   $c->whatever( foo => 1234 );

And so on.

=head1 METHODS

=over 4

=item B<< $class->with_traits( @traits ) >>

Return a new class with the traits applied.  Use like:

=item B<< $class->new_with_traits(%args, traits => \@traits) >>

C<new_with_traits> can also take a hashref, e.g.:

  my $instance = $class->new_with_traits({ traits => \@traits, foo => 'bar' });

=back

=head1 ATTRIBUTES YOUR CLASS GETS

This role will add the following attributes to the consuming class.

=head2 _trait_namespace

You can override the value of this attribute with C<default> to
automatically prepend a namespace to the supplied traits.  (This can
be overridden by prefixing the trait name with C<+>.)

Example:

  package Another::Trait;
  use Moose::Role;
  has 'bar' => (
      is       => 'ro',
      isa      => 'Str',
      required => 1,
  );

  package Another::Class;
  use Moose;
  with 'MooseX::Traits';
  has '+_trait_namespace' => ( default => 'Another' );

  my $instance = Another::Class->new_with_traits(
      traits => ['Trait'], # "Another::Trait", not "Trait"
      bar    => 'bar',
  );
  $instance->does('Trait')          # false
  $instance->does('Another::Trait') # true

  my $instance2 = Another::Class->new_with_traits(
      traits => ['+Trait'], # "Trait", not "Another::Trait"
  );
  $instance2->does('Trait')          # true
  $instance2->does('Another::Trait') # false

=head1 AUTHORS and CONTRIBUTORS

Jonathan Rockway C<< <jrockway@cpan.org> >>

Stevan Little C<< <stevan.little@iinteractive.com> >>

Tomas Doran C<< <bobtfish@bobtfish.net> >>

Matt S. Trout C<< <mst@shadowcatsystems.co.uk> >>

Jesse Luehrs C<< <doy at tozt dot net> >>

Shawn Moore C<< <sartak@bestpractical.com> >>

Florian Ragwitz C<< <rafl@debian.org> >>

Chris Prather C<< <chris@prather.org> >>

Yuval Kogman C<< <nothingmuch@woobling.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright 2008 Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

