package Bric::Util::UserPref;

=head1 NAME

Bric::Util::UserPref - Interface to Bricolage per-user preferences.

=head1 VERSION

$Revision: 1.2 $

=cut

# Grab the Version Number.
our $VERSION = (qw$Revision: 1.2 $ )[-1];

=head1 DATE

$Date: 2003-12-22 04:07:29 $

=head1 SYNOPSIS

  use Bric::Util::UserPref;

  # Constructors.
  my $user_pref = Bric::Util::UserPref->new($init);
  $user_pref = Bric::Util::UserPref->lookup({ id => $id });
  $user_pref = Bric::Util::UserPref->lookup({ name => $name });
  my @prefs = Bric::Util::UserPref->list($params);

  # Class Methods.
  my @pref_ids = Bric::Util::UserPref->list_ids($params);
  my $meths = Bric::Util::UserPref->my_meths;
  my @meths = Bric::Util::UserPref->my_meths(1);

  # Instance Methods
  my $pref_id = $user_pref->get_pref_id;
  my $name = $user_pref->get_name;
  my $desc = $user_pref->get_description;
  my $default = $user_pref->get_default;
  my $opt_type = $user_pref->get_opt_type;
  my $val_name = $user_pref->get_val_name;

  # Get a list of available value options.
  my @opts = $user_pref->get_opts;
  my $opts_ref = $user_pref->get_opts_href;

  # Get the associated Bric::Util::Pref object
  my $pref = $user_pref->get_pref;

  # Get and set the value.
  my $value = $user_pref->get_value;
  $user_pref = $user_pref->set_value($value);

  # Save the pref.
  $user_pref = $user_pref->save;

=head1 DESCRIPTION

This is the central interface for managing Bricolage application
preferences. It should scale when we later decide to add user and user group
preferences. Right now it'll just support those global application preferences
that we deem necessary for the application to work, such as Time Zone.

=cut

################################################################################
# Dependencies
################################################################################
# Standard Dependencies
use strict;

################################################################################
# Programmatic Dependences
use Bric::Util::DBI qw(:all);
use Bric::Util::Fault qw(throw_dp);

################################################################################
# Inheritance
################################################################################
use base qw(Bric);

################################################################################
# Function and Closure Prototypes
################################################################################
my ($get_em, $get_opts, $pref);

################################################################################
# Constants
################################################################################
use constant DEBUG => 0;

################################################################################
# Fields
################################################################################
# Public Class Fields

################################################################################
# Private Class Fields
my $SEL_COLS = 'up.id, p.id, p.name, p.description, p.def, up.value, p.manual, ' .
  'p.opt_type, o.description, p.can_be_overridden, up.usr__id';
my @SEL_PROPS = qw(id pref_id name description default value manual opt_type val_name
                   can_be_overridden user_id);

my @ORD = @SEL_PROPS[1..$#SEL_PROPS-1];
my @upcols  = qw(id pref__id usr__id value);
my @upprops = qw(id pref_id user_id value);
my $user_prefkey = '__USER_PREF__';
my $METHS;

################################################################################

################################################################################
# Instance Fields
BEGIN {
    Bric::register_fields({
                         # Public Fields
                         id => Bric::FIELD_READ,
                         pref_id => Bric::FIELD_READ,
                         user_id => Bric::FIELD_RDWR,
                         name => Bric::FIELD_READ,
                         description => Bric::FIELD_READ,
                         value => Bric::FIELD_RDWR,
                         default => Bric::FIELD_READ,
                         manual => Bric::FIELD_READ,
                         val_name => Bric::FIELD_READ,
                         can_be_overridden => Bric::FIELD_READ,
                         opt_type => Bric::FIELD_READ,

                         # Private Fields
                         _val_ch => Bric::FIELD_NONE
                        });
}

################################################################################
# Class Methods
################################################################################

=head1 INTERFACE

=head2 Constructors

=over 4

=item my $user_pref = Bric::Util::Pref->lookup({ id => $id })

=item my $user_pref = Bric::Util::Pref->lookup({ name => $name })

Looks up and instantiates a new Bric::Util::Pref object based on the
Bric::Util::Pref object ID or name passed. If $id or $name is not found in the
database, lookup() returns undef.

B<Throws:>

=over

=item *

Too many Bric::Dist::Util::Pref objects found.

=item *

Unable to connect to database.

=item *

Unable to prepare SQL statement.

=item *

Unable to connect to database.

=item *

Unable to select column into arrayref.

=item *

Unable to execute SQL statement.

=item *

Unable to bind to columns to statement handle.

=item *

Unable to fetch row from statement handle.

=back

B<Side Effects:> If $id is found, populates the new Bric::Util::Pref object with
data from the database before returning it.

B<Notes:> NONE.

=cut

sub lookup {
    my $pkg = shift;

    my $user_pref = $pkg->cache_lookup(@_);
    return $user_pref if $user_pref;

    $user_pref = $get_em->($pkg, @_);
    # We want @$user_pref to have only one value.
    throw_dp(error => 'Too many Bric::Util::UserPref objects found.')
      if @$user_pref > 1;
    return @$user_pref ? $user_pref->[0] : undef;
}

################################################################################

=item my (@prefs || $user_prefs_aref) = Bric::Util::Pref->list($params)

Returns a list or anonymous array of Bric::Util::Pref objects based on the search
parameters passed via an anonymous hash. The supported lookup keys are:

=over 4

=item *

id

=item *

pref_id

=item *

user_id

=item *

description

=item *

default

=item *

value

=item *

val_name

=item *

manual

=item *

opt_type

=item *

grp_id

=back

B<Throws:>

=over 4

=item *

Unable to connect to database.

=item *

Unable to prepare SQL statement.

=item *

Unable to connect to database.

=item *

Unable to select column into arrayref.

=item *

Unable to execute SQL statement.

=item *

Unable to bind to columns to statement handle.

=item *

Unable to fetch row from statement handle.

=back

B<Side Effects:> Populates each Bric::Util::Pref object with data from the
database before returning them all.

B<Notes:> NONE.

=cut

sub list { wantarray ? @{ &$get_em(@_) } : &$get_em(@_) }

################################################################################

=back

=head2 Destructors

=over 4

=item $user_pref->DESTROY

Dummy method to prevent wasting time trying to AUTOLOAD DESTROY.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=back

=cut

sub DESTROY {}

################################################################################

=head2 Public Class Methods

=over 4

=item $meths = Bric::Util::Pref->my_meths

=item (@meths || $meths_aref) = Bric::Util::Pref->my_meths(TRUE)

=item my (@meths || $meths_aref) = Bric::Util::Pref->my_meths(0, TRUE)

Returns an anonymous hash of introspection data for this object. If called
with a true argument, it will return an ordered list or anonymous array of
introspection data. If a second true argument is passed instead of a first,
then a list or anonymous array of introspection data will be returned for
properties that uniquely identify an object (excluding C<id>, which is
assumed).

Each hash key is the name of a property or attribute of the object. The value
for a hash key is another anonymous hash containing the following keys:

=over 4

=item name

The name of the property or attribute. Is the same as the hash key when an
anonymous hash is returned.

=item disp

The display name of the property or attribute.

=item get_meth

A reference to the method that will retrieve the value of the property or
attribute.

=item get_args

An anonymous array of arguments to pass to a call to get_meth in order to
retrieve the value of the property or attribute.

=item set_meth

A reference to the method that will set the value of the property or
attribute.

=item set_args

An anonymous array of arguments to pass to a call to set_meth in order to set
the value of the property or attribute.

=item type

The type of value the property or attribute contains. There are only three
types:

=over 4

=item short

=item date

=item blob

=back

=item len

If the value is a 'short' value, this hash key contains the length of the
field.

=item search

The property is searchable via the list() and list_ids() methods.

=item req

The property or attribute is required.

=item props

An anonymous hash of properties used to display the property or
attribute. Possible keys include:

=over 4

=item type

The display field type. Possible values are

=over 4

=item text

=item textarea

=item password

=item hidden

=item radio

=item checkbox

=item select

=back

=item length

The Length, in letters, to display a text or password field.

=item maxlength

The maximum length of the property or value - usually defined by the SQL DDL.

=back

=item rows

The number of rows to format in a textarea field.

=item cols

The number of columns to format in a textarea field.

=item vals

An anonymous hash of key/value pairs reprsenting the values and display names
to use in a select list.

=back

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

my @attrs_from_pref = qw(name description default
                         can_be_overridden opt_type);

# Why the *BEEP* doesn't Bric.pm use my_meths to find the get & set
# methods instead of auto-generating them?!
foreach my $attr (@attrs_from_pref)
{
    my $get_meth = "get_$attr";

    no strict 'refs';
    *{$get_meth} = sub { shift->get_pref->$get_meth() };
}

sub my_meths {
    my ($pkg, $ord, $ident) = @_;

    return if $ident;

    unless ($METHS) {
        my %meths;

        my $pref_meths = Bric::Util::Pref->my_meths;

        # Copy the various attribute methods from Bric::Util::Pref, remove
        # the setter, and change the getter to use $pref->get_*
        foreach my $attr (@attrs_from_pref) {
            # make a copy so we don't alter the original
            my %copy = %{ $pref_meths->{$attr} };
            delete $copy{set_meth};
            delete $copy{set_args};

            my $get_meth = "get_$attr";
            $copy{get_meth} = sub { shift->$get_meth() };

            $meths{$attr} = \%copy;
        }

        $METHS = { %meths,
                   value      => {
                                  name     => 'value',
                                  get_meth => sub { shift->get_value(@_) },
                                  get_args => [],
                                  set_meth => sub { shift->set_value(@_) },
                                  set_args => [],
                                  disp     => 'Value',
                                  len      => 256,
                                  req      => 0,
                                  type     => 'short',
                                  props    => { type => 'textarea',
                                                cols => 40,
                                                rows => 4
                                              }
                                 },
                   val_name   => {
                                  name     => 'val_name',
                                  get_meth => sub { shift->get_val_name(@_) },
                                  get_args => [],
                                  disp     => 'Value Name',
                                  len      => 256,
                                  req      => 0,
                                 },
                   pref_id    => {
                                  name     => 'pref_id',
                                  get_meth => sub { $_[0]->get_pref_id },
                                  get_args => [],
                                 },
                   user_id    => {
                                  name     => 'user_id',
                                  get_meth => sub { $_[0]->get_user_id },
                                  get_args => [],
                                 },
                 };
    }

    if ($ord) {
        return wantarray ? @{$METHS}{@ORD} : [@{$METHS}{@ORD}];
    } else {
        return $METHS;
    }
}

################################################################################

=back

=head2 Public Instance Methods

=over 4

=item my $id = $user_pref->get_pref_id

Returns the ID of the Bric::Util::UserPref object.

B<Throws:>

=over 4

=item *

Bad AUTOLOAD method format.

=item *

Cannot AUTOLOAD private methods.

=item *

Access denied: READ access for field 'id' required.

=item *

No AUTOLOAD method.

=back

B<Side Effects:> NONE.


B<Notes:> If the Bric::Util::UserPref object has been instantiated via the new()
constructor and has not yet been C<save>d, the object will not yet have an ID,
so this method call will return undef.

=item my $pref_id = $user_pref->get_pref_id

Returns the pref ID of the Bric::Util::UserPref object.

B<Throws:>

=over 4

=item *

Bad AUTOLOAD method format.

=item *

Cannot AUTOLOAD private methods.

=item *

Access denied: READ access for field 'pref_id' required.

=item *

No AUTOLOAD method.

=back

B<Side Effects:> NONE.

=item my $pref_id = $user_pref->get_user_id

Returns the user ID of the Bric::Util::UserPref object.

B<Throws:>

=over 4

=item *

Bad AUTOLOAD method format.

=item *

Cannot AUTOLOAD private methods.

=item *

Access denied: READ access for field 'user_id' required.

=item *

No AUTOLOAD method.

=back

B<Side Effects:> NONE.

=item my $name = $user_pref->get_name

Returns preference name.

B<Throws:>

=over 4

=item *

Bad AUTOLOAD method format.

=item *

Cannot AUTOLOAD private methods.

=item *

Access denied: READ access for field 'name' required.

=item *

No AUTOLOAD method.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=item my $description = $user_pref->get_description

Returns preference description.

B<Throws:>

=over 4

=item *

Bad AUTOLOAD method format.

=item *

Cannot AUTOLOAD private methods.

=item *

Access denied: READ access for field 'description' required.

=item *

No AUTOLOAD method.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=item my $default = $user_pref->get_default

Returns preference default.

B<Throws:>

=over 4

=item *

Bad AUTOLOAD method format.

=item *

Cannot AUTOLOAD private methods.

=item *

Access denied: READ access for field 'default' required.

=item *

No AUTOLOAD method.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=item my $value = $user_pref->get_value

Returns the preference value.

B<Throws:>

=over 4

=item *

Bad AUTOLOAD method format.

=item *

Cannot AUTOLOAD private methods.

=item *

Access denied: READ access for field 'value' required.

=item *

No AUTOLOAD method.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=item $self = $user_pref->set_value($value)

Sets the preference value.

B<Throws:>

=over 4

=item *

Incorrect number of args to _set().

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub set_value {
    my ($self, $val) = @_;
    $self->_set([qw(value _val_ch)], [$val, 1]);
}

=item my $opt_type = $user_pref->get_opt_type

Returns preference opt_type ('select', 'radio', 'text', ...).

B<Throws:>

=over 4

=item *

Bad AUTOLOAD method format.

=item *

Cannot AUTOLOAD private methods.

=item *

Access denied: READ access for field 'opt_type' required.

=item *

No AUTOLOAD method.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=item my $val_name = $user_pref->get_val_name

Returns preference value's descriptive name. Note that if you've set the value,
this method will return an incorrect value unless and until you instantiate the
object again using lookup() or list().

B<Throws:>

=over 4

=item *

Problems retrieving fields.

=item *

Unable to connect to database.

=item *

Unable to prepare SQL statement.

=item *

Unable to select column into arrayref.

=item *

Incorrect number of args to _set().

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

=item my $user_id = $user_pref->get_user_id

Returns the user id for this usre preference.

B<Throws:>

=over 4

=item *

Bric::_get() - Problems retrieving fields.

=item *

Unable to connect to database.

=item *

Unable to prepare SQL statement.

=item *

Unable to connect to database.

=item *

Unable to execute SQL statement.

=item *

Unable to bind to columns to statement handle.

=item *

Unable to fetch row from statement handle.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

=item my (@opts || $opts_aref) = $user_pref->get_opts

Returns a list or anonymous array of options available for filling in the value
of this preference.

B<Throws:>

=over 4

=item *

Bric::_get() - Problems retrieving fields.

=item *

Unable to connect to database.

=item *

Unable to prepare SQL statement.

=item *

Unable to connect to database.

=item *

Unable to execute SQL statement.

=item *

Unable to bind to columns to statement handle.

=item *

Unable to fetch row from statement handle.

=item *

Incorrect number of args to Bric::_set().

=item *

Bric::set() - Problems setting fields.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub get_opts { wantarray ? sort keys %{ &$get_opts($_[0]) }
                 : [ sort keys %{ &$get_opts($_[0]) } ];
}

################################################################################

=item my $opts_href = $user_pref->get_opts_href

Returns a hashref of options available for filling in the value of this
preference. The hash keys are the options, and the values are their
descriptions.

B<Throws:>

=over 4

=item *

Bric::_get() - Problems retrieving fields.

=item *

Unable to connect to database.

=item *

Unable to prepare SQL statement.

=item *

Unable to connect to database.

=item *

Unable to execute SQL statement.

=item *

Unable to bind to columns to statement handle.

=item *

Unable to fetch row from statement handle.

=item *

Incorrect number of args to Bric::_set().

=item *

Bric::set() - Problems setting fields.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub get_opts_href { &$get_opts($_[0]) }

################################################################################

=item $pref = $user_pref->pref()

Loads the Bric::Util::Pref object for the given user preference object.

B<Throws:>

=over 4

??

=back

B<Side Effects:> NONE.

B<Notes:> Uses Bric::App::Cache for persistence across processes.

=cut

sub get_pref {
    my $self = shift;
    return Bric::Util::Pref->lookup({ id => $self->get_pref_id });
};

################################################################################

=item $self = $user_pref->save

Saves any changes to the Bric::Util::Pref object. Returns $self on success and
undef on failure.

B<Throws:>

=over 4

=item *

Bric::_get() - Problems retrieving fields.

=item *

Unable to connect to database.

=item *

Unable to prepare SQL statement.

=item *

Unable to execute SQL statement.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub save {
    my $self = shift;
    return unless $self->_get__dirty;
    my ($id, $name, $value) =
        $self->_get(qw(id name value));

    my $sql;
    if (defined $id) {
        my $upd = prepare_c(qq{
        UPDATE usr_pref
        SET    value = ?
        WHERE  id = ?
        }, undef);

        execute($upd, $self->get_value, $id);
    } else {
        my $fields = join ', ', next_key('usr_pref'), ('?') x $#upcols;

        local $" = ',';
        my $ins = prepare_c(qq{
        INSERT INTO usr_pref(@upcols)
        VALUES ($fields)
        }, undef);

        # Update the database.
        execute($ins, $self->_get(@upprops[1..$#upprops]));

        # Now grab the ID.
        $id = last_key('usr_pref');
        $self->_set(['id'], [$id]);
    }

    $self->SUPER::save;

    $self;
}

################################################################################

=item $self = $user_pref->delete

Delete a user preference from the database.

B<Throws:>

=over 4

=item *

Bric::_get() - Problems retrieving fields.

=item *

Unable to connect to database.

=item *

Unable to prepare SQL statement.

=item *

Unable to execute SQL statement.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub delete {
    my $self = shift;

    my $id = $self->get_id;

    return unless defined $id;

    $self->uncache_me;

    my $del = prepare_c(qq{
    DELETE FROM usr_pref
    WHERE  id = ?
    }, undef);

    execute($del, $id);
}

################################################################################

=back

=head1 PRIVATE

=head2 Private Class Methods

NONE.

=head2 Private Instance Methods

NONE.

=head2 Private Functions

=over 4

=item my $user_pref_aref = &$get_em( $pkg, $params )

=item my $user_pref_ids_aref = &$get_em( $pkg, $params, 1 )

Function used by lookup() and list() to return a list of Bric::Util::Pref objects
or, if called with an optional third argument, returns a list of Bric::Util::Pref
object IDs (used by list_ids()).

B<Throws:>

=over 4

=item *

Unable to connect to database.

=item *

Unable to prepare SQL statement.

=item *

Unable to connect to database.

=item *

Unable to select column into arrayref.

=item *

Unable to execute SQL statement.

=item *

Unable to bind to columns to statement handle.

=item *

Unable to fetch row from statement handle.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

$get_em = sub {
    my ($pkg, $params, $href) = @_;
    my $tables = 'pref p, usr_pref up, pref_opt o, member m, pref_member c';
    my $wheres = 'p.id = o.pref__id AND up.value = o.value AND p.id = up.pref__id ' .
      'AND p.id = c.object_id AND m.id = c.member__id AND m.active = 1';
    my @params;
    while (my ($k, $v) = each %$params) {
        if ($k eq 'id') {
            $wheres .= " AND up.id = ?";
            push @params, $v;
        } elsif ($k eq 'pref_id') {
            $wheres .= " AND p.id = ?";
            push @params, $v;
        } elsif ($k eq 'val_name') {
            $wheres .= " AND LOWER(o.description) LIKE ?";
            push @params, lc $v;
        } elsif ($k eq 'grp_id') {
            # Add in the group tables a second time and join to them.
            $tables .= ", member m2, pref_member c2";
            $wheres .= " AND p.id = c2.object_id AND c2.member__id = m2.id" .
              " AND m2.active = 1 AND m2.grp__id = ?";
            push @params, $v;
        } elsif ($k eq 'user_id') {
            $wheres .= ' AND up.usr__id = ?';
            push @params, $v;
        } elsif ($k eq 'can_be_overridden') {
            $wheres .= " AND p.can_be_overridden = ?";
            push @params, $v ? 1 : 0;
        } elsif ($k eq 'active') {
            # Preferences have no active column.
            next;
        } else {
            $k = 'def' if $k eq 'default';
            # It's a varchar field.
            $wheres .= " AND LOWER(p.$k) LIKE ?";
            push @params, lc $v;
        }
    }

    # Assemble and prepare the query.
    my ($qry_cols, $order) = (\$SEL_COLS, 'p.name, up.id');
    my $sel = prepare_c(qq{
        SELECT $$qry_cols
        FROM   $tables
        WHERE  $wheres
        ORDER BY $order
    }, undef);

    execute($sel, @params);
    my (@d, @prefs, $grp_ids);
    $pkg = ref $pkg || $pkg;
    bind_columns($sel, \@d[0..$#SEL_PROPS]);
    my $last = -1;
    while (fetch($sel)) {
        # Create a new user pref object.
        my $self = bless {}, $pkg;
        $self->SUPER::new;
        # Get a reference to the array of group IDs.
        $self->_set(\@SEL_PROPS, \@d);
        $self->_set__dirty; # Disables dirty flag.
        push @prefs, $self->cache_me;
    }
    return \@prefs;
};


1;
__END__

=back

=head1 NOTES

NONE.

=head1 AUTHOR

David Wheeler <david@wheeler.net>

=head1 SEE ALSO

L<Bric|Bric>

=cut