package Bric::Biz::Asset::Business;
###############################################################################

=head1 NAME

Bric::Biz::Asset::Business - An object that houses the business Assets

=head1 VERSION

$Revision: 1.24 $

=cut

our $VERSION = (qw$Revision: 1.24 $ )[-1];

=head1 DATE

$Date: 2002-09-27 22:21:03 $

=head1 SYNOPSIS

 # Constructor
 $biz = Bric::Biz::Asset::Business->new($param);
 # DB object looukp
 $biz = Bric::Biz::Asset::Business->lookup({'id' => $biz_id});

 # Getting a list of objects
 ($biz_asset_list||@biz_assets) = Bric::Biz::Asset::Business->list( $criteria )

 # Geting a list of ids
 ($biz_ids || @biz_ids) = Bric::Biz::Asset::Business->list_ids( $criteria )


 ## METHODS INHERITED FROM Bric::Biz::Asset ##

 # Class Methods
 $key_name = Bric::Biz::Asset->key_name()
 %priorities = Bric::Biz::Asset->list_priorities()
 $data = Bric::Biz::Asset->my_meths

 # looking up of objects
 ($asset_list || @assets) = Bric::Biz::Asset->list( $param )

 # General information
 $asset       = $asset->get_id()
 $asset       = $asset->set_name($name)
 $name        = $asset->get_name()
 $asset       = $asset->set_description($description)
 $description = $asset->get_description()
 $priority    = $asset->get_priority()
 $asset       = $asset->set_priority($priority)

 # User information
 $usr_id      = $asset->get_user__id()
 $modifier    = $asset->get_modifier()

 # Version information
 $vers        = $asset->get_version();
 $vers_id     = $asset->get_version_id();
 $current     = $asset->get_current_version();
 $checked_out = $asset->get_checked_out()

 # Expire Data Information
 $asset       = $asset->set_expire_date($date)
 $expire_date = $asset->get_expire_date()

 # Desk stamp information
 ($desk_stamp_list || @desk_stamps) = $asset->get_desk_stamps()
 $desk_stamp                        = $asset->get_current_desk()
 $asset                             = $asset->set_current_desk($desk_stamp)

 # Workflow methods.
 $id    = $asset->get_workflow_id;
 $obj   = $asset->get_workflow_object;
 $asset = $asset->set_workflow_id($id);

 # Output channel associations.
 my @ocs = $asset->get_output_channels;
 $asset->add_output_channels(@ocs);
 $asset->del_output_channels(@ocs);

 # Access note information
 $asset                 = $asset->add_note($note)
 ($note_list || @notes) = $asset->get_notes()

 # Access active status
 $asset            = $asset->deactivate()
 $asset            = $asset->activate()
 ($asset || undef) = $asset->is_active()

 $asset = $asset->save()

 # returns all the groups this is a member of
 ($grps || @grps) = $asset->get_grp_ids()


=head1 DESCRIPTION

This is the parent class for all the business assets ( i.e. Stories, images
etc.)

Assumption here is that all Business assets have rights, publish dates
and keywords associated with them.

This class contains all the interfact to these data points

=cut

#==============================================================================#
# Dependencies                         #
#======================================#

#--------------------------------------#
# Standard Dependencies

use strict;

#--------------------------------------#
# Programatic Dependencies

use Bric::Util::DBI qw(:all);
use Bric::Util::Time qw(:all);
use Bric::Util::Grp::AssetVersion;
use Bric::Util::Grp::AssetLanguage;
use Bric::Biz::Asset::Business::Parts::Tile::Data;
use Bric::Biz::Asset::Business::Parts::Tile::Container;
use Bric::Biz::Category;
use Bric::Biz::OutputChannel qw(:case_constants);
use Bric::Biz::Org::Source;
use Bric::Util::Coll::OutputChannel;
use Bric::Util::Pref;

#=============================================================================#
# Inheritance                          #
#======================================#

use base qw( Bric::Biz::Asset );

#============================================================================+
# Function Prototypes                  #
#======================================#
my $get_oc_coll;

#=============================================================================#
# Constants                            #
#======================================#

use constant DEBUG => 0;

#=============================================================================#
# Fields                               #
#======================================#

#--------------------------------------#
# Public Class Fields

# None

#--------------------------------------#
# Private Class Fields
my $meths;
my @ord;

my %uri_format_hash = ( 'categories' => '',
                        'day'        => '%d',
                        'month'      => '%m',
                        'slug'       => '',
                        'year'       => '%Y' );
#--------------------------------------#
# Instance Fields

BEGIN {
        Bric::register_fields
            ({
              # Public Fields
              source__id                => Bric::FIELD_RDWR,
              element__id               => Bric::FIELD_RDWR,
              related_grp__id           => Bric::FIELD_READ,
              primary_uri               => Bric::FIELD_READ,
              publish_date              => Bric::FIELD_RDWR,
              cover_date                => Bric::FIELD_RDWR,
              publish_status            => Bric::FIELD_RDWR,


              # Private Fields
              _contributors             => Bric::FIELD_NONE,
              _queried_contrib          => Bric::FIELD_NONE,
              _del_contrib              => Bric::FIELD_NONE,
              _update_contributors      => Bric::FIELD_NONE,
              _related_grp_obj          => Bric::FIELD_NONE,
              _tile                     => Bric::FIELD_NONE,
              _queried_cats             => Bric::FIELD_NONE,
              _categories               => Bric::FIELD_NONE,
              _del_categories           => Bric::FIELD_NONE,
              _new_categories           => Bric::FIELD_NONE,
              _element_object           => Bric::FIELD_NONE,
              _oc_coll                  => Bric::FIELD_NONE,
            });
    }

#=============================================================================#

=head1 INTERFACE

=head2 Constructors

=over 4

=cut

#--------------------------------------#
# Constructors

#-----------------------------------------------------------------------------#

=item $asset = Bric::Biz::Asset::Business->new( $initial_state )

new will only be called by Bric::Biz::Asset::Business's inherited classes

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub new {
    my ($self, $init) = @_;
    $self = bless {}, $self unless ref $self;
    $self->_init($init);
    $self->SUPER::new($init);
}

###############################################################################


=item $asset = Bric::Biz::Asset::Business->lookup( { id => $id} )

This will die because only the inherited classes will be looked up

B<Throws:>

"Method Not Implemented"

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub lookup {
        my ($self) = @_;

        die Bric::Util::Fault::Exception::MNI->new( {
                        msg => "Method not implemented" });
}

###############################################################################


=item ($obj_list||@objs) = Bric::Biz::Asset::Business->list( $criteria )

This will return a list or list ref of Business assets that match the given
criteria

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub list {
        my ($class, $param) = @_;

        my @stories = Bric::Biz::Asset::Business::Story->list($param);
        my @media = Bric::Biz::Asset::Business::Media->list($param);

        my @all = (@stories, @media);

        return wantarray ? @all : \@all;
}

###############################################################################


#--------------------------------------#

=back

=head2 Destructors

=over 4

=item $self->DESTROY

Dummy method to prevent wasting time trying to AUTOLOAD DESTROY.

=cut

sub DESTROY {
        # This method should be here even if its empty so that we don't waste time
        # making Bricolage's autoload method try to find it.
}

###############################################################################


#--------------------------------------#

=back

=head2 Public Class Methods

=over 4

=item list ids is not allowed for parent classes

You will have to use list to get all the objects

B<Throws:>

"method not implemented"

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub list_ids {
        die Bric::Util::Fault::Exception::MNI->new(
                { msg => "Method Not Implemented" });
}

################################################################################

=item my $key_name = Bric::Biz::Asset::Business->key_name()

Returns the key name of this class.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub key_name { 'biz' }

################################################################################

=item $meths = Bric::Biz::Asset::Business->my_meths

=item (@meths || $meths_aref) = Bric::Biz::Asset::Business->my_meths(TRUE)

Returns an anonymous hash of instrospection data for this object. If called with
a true argument, it will return an ordered list or anonymous array of
intrspection data. The format for each introspection item introspection is as
follows:

Each hash key is the name of a property or attribute of the object. The value
for a hash key is another anonymous hash containing the following keys:

=over 4

=item *

name - The name of the property or attribute. Is the same as the hash key when
an anonymous hash is returned.

=item *

disp - The display name of the property or attribute.

=item *

get_meth - A reference to the method that will retrieve the value of the
property or attribute.

=item *

get_args - An anonymous array of arguments to pass to a call to get_meth in
order to retrieve the value of the property or attribute.

=item *

set_meth - A reference to the method that will set the value of the
property or attribute.

=item *

set_args - An anonymous array of arguments to pass to a call to set_meth in
order to set the value of the property or attribute.

=item *

type - The type of value the property or attribute contains. There are only
three types:

=over 4

=item short

=item date

=item blob

=back

=item *

len - If the value is a 'short' value, this hash key contains the length of the
field.

=item *

search - The property is searchable via the list() and list_ids() methods.

=item *

req - The property or attribute is required.

=item *

props - An anonymous hash of properties used to display the property or attribute.
Possible keys include:

=over 4

=item type

The display field type. Possible values are

=item text

=item textarea

=item password

=item hidden

=item radio

=item checkbox

=item select

=back

=item *

length - The Length, in letters, to display a text or password field.

=item *

maxlength - The maximum length of the property or value - usually defined by the
SQL DDL.

=item *

rows - The number of rows to format in a textarea field.

=item *

cols - The number of columns to format in a textarea field.

=item *

vals - An anonymous hash of key/value pairs reprsenting the values and display
names to use in a select list.

=back

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub my_meths {
    my ($pkg, $ord) = @_;

    # Return 'em if we got em.
    return !$ord ? $meths : wantarray ? @{$meths}{@ord} : [@{$meths}{@ord}]
      if $meths;

    # We don't got 'em. So get 'em!
    foreach my $meth (__PACKAGE__->SUPER::my_meths(1)) {
        $meths->{$meth->{name}} = $meth;
        push @ord, $meth->{name};
        push (@ord, 'title') if $meth->{name} eq 'name';
    }
    push @ord, qw(source_id source publish_date), pop @ord;

    $meths->{source_id} =    {
                              name     => 'source_id',
                              get_meth => sub { shift->get_source__id(@_) },
                              get_args => [],
                              set_meth => sub { shift->set_source__id(@_) },
                              set_args => [],
                              disp     => 'Source ID',
                              len      => 1,
                              req      => 1,
                              type     => 'short',
                             };
    $meths->{source} =       {
                              name     => 'source',
                              get_meth => sub { Bric::Biz::Org::Source->lookup({ id => shift->get_source__id(@_) }) },
                              get_args => [],
                              disp     => 'Source',
                              len      => 1,
                              type     => 'short',
                             };
    $meths->{publish_date} = {
                              name     => 'publish_date',
                              get_meth => sub { shift->get_publish_date(@_) },
                              get_args => [],
                              set_meth => sub { shift->set_publish_date(@_) },
                              set_args => [],
                              disp     => 'Publish Date',
                              len      => 64,
                              req      => 0,
                              type     => 'short',
                              props    => { type => 'date' }
                             };

    # Copy the data for the title from name.
    $meths->{title} = { %{ $meths->{name} } };
    $meths->{title}{name} = 'title';
    $meths->{title}{disp} = 'Title';

    return !$ord ? $meths : wantarray ? @{$meths}{@ord} : [@{$meths}{@ord}];
}

###############################################################################

=back

=head2 Public Instance Methods

=over 4

=item $title = $asset->get_title()

Returns the title field for this asset

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

title is the same as the name field

=cut

sub get_title { $_[0]->_get('name') }

################################################################################

=item $asset = $asset->set_title($title)

sets the title for this asset

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

title is the same as the name field

=cut

sub set_title { $_[0]->_set(['name'] => [$_[1]]) }

################################################################################

=item $biz = $biz->set_source__id($s_id)

Sets the source id upon this story

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

################################################################################

=item $source = $biz->get_source__id()

Returns the source id from this business asset

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

################################################################################

=item $at_id = $biz->get_element__id()

Returns the asset type id that this story is associated with

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

################################################################################

=item $biz = $biz->set_element__id($at_id)

Sets the asset type id that this story is associated with.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub set_element__id {
    my ($self, $eid) = @_;
    my $old_eid = $self->_get('element__id');
    return $self if $eid == $old_eid;
    my $oc_coll = $get_oc_coll->($self);
    $oc_coll->del_objs;
    my $elem = Bric::Biz::AssetType->lookup({ id => $eid });
    $oc_coll->add_new_objs( map { $_->is_enabled ? $_ : () }
                            $elem->get_output_channels );
    $self->_set([qw(element__id element)], [$eid, $elem]);
}

################################################################################

=item $biz->add_contributor($contrib, $role );

Takes a contributor object or id and their role in the context of this story
and associates them

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub add_contributor {
    my ($self, $contrib, $role) = @_;
    my $dirty = $self->_get__dirty();
    my $contribs = $self->_get_contributors() || {};

    # get the contributor id
    my $c_id = ref $contrib ? $contrib->get_id() : $contrib;
    my $place = scalar keys %$contribs;
    if (exists $contribs->{$c_id}) {
        # already a contrib, update role if need be
        $contribs->{$c_id}->{'role'} = $role;
        $contribs->{$c_id}->{'obj'} = ref $contrib ? $contrib : undef;
        unless ($contribs->{$c_id}->{'action'} &&
                $contribs->{$c_id}->{'action'} eq 'insert') {
            $contribs->{$c_id}->{'action'} = 'update';
        }
    } else {
        $contribs->{$c_id}->{'role'} = $role;
        $contribs->{$c_id}->{'obj'} = ref $contrib ? $contrib : undef;
        $contribs->{$c_id}->{'place'} = $place;
        $contribs->{$c_id}->{'action'} = 'insert';
    }

    $self->_set({
                 '_contributors' => $contribs,
                 '_update_contributors' => 1
                });

    $self->_set__dirty($dirty);
    return $self;
}

=item ($contribs || @contribs) = $story->get_contributors()

Returns a list or list ref of the contributors that have been assigned
to this story

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub get_contributors {
    my $self = shift;
    my $contribs = $self->_get_contributors();

    my @contribs;
    foreach my $id (sort { $contribs->{$a}->{'place'} <=>
                           $contribs->{$b}->{'place'} }
                    keys %$contribs) {
        if (defined $contribs->{$id}->{'obj'}) {
            push @contribs, $contribs->{$id}->{'obj'};
        } else {
            push @contribs, Bric::Util::Grp::Parts::Member::Contrib->lookup
              ({ id => $id });
        }
    }
    return wantarray ? @contribs : \@contribs;
}

################################################################################

=item $role = $biz->get_contributor_role($contrib)

Returns the role played by this contributor

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub get_contributor_role {
    my $self = shift;
    my ($contrib) = @_;
    my $c_id = ref $contrib ? $contrib->get_id : $contrib;
    my $contribs = $self->_get_contributors;

    return unless exists $contribs->{$c_id};
    return $contribs->{$c_id}->{'role'};
}

################################################################################

=item $story = $story->delete_contributors( $contributors )

Recieves a list of contributrs or their ids and deletes them from the story

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub delete_contributors {
    my ($self, $contributors) = @_;
    my $dirty = $self->_get__dirty();
    my $contribs = $self->_get_contributors();
    my $delete = $self->_get('_del_contrib');

    foreach (@$contributors) {
        my $id = ref $_ ? $_->get_id : $_;
        if ($contribs->{$id}->{'action'}
            && $contribs->{$id}->{'action'} eq 'insert') {
            delete $contribs->{$id};
        } else {
            $delete->{$id} = delete $contribs->{$id};
        }
    }

    # update the order fields for the remaining contribs
    my $i = 0;
    foreach (keys %$contribs) {
        if ($contribs->{$_}->{'place'} != $i) {
            $contribs->{$_}->{'place'} = $i;
            $contribs->{$_}->{action} ||= 'update';
        }
        $i++;
    }

    $self->_set( {
                  _contributors         => $contribs,
                  _update_contributors  => 1,
                  _del_contrib                  => $delete
                 });

    $self->_set__dirty($dirty);
    return $self;
}

=item $asset = $asset->reorder_contributors(@contributors)

Takes a list of ids and sets the new order upon them

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub reorder_contributors {
        my $self = shift;
        my @new_order = @_;

        my $dirty = $self->_get__dirty();

        my $existing = $self->_get_contributors();

        if ((scalar @new_order) != (scalar (keys %$existing))) {
                die Bric::Util::Fault::Exception::GEN->new( 
                        { 'msg' => 'Improper Args to reorder contributors' });
        }

        my $i = 0;
        foreach (@new_order) {
                if (exists $existing->{$_}) {
                        unless ($existing->{$_}->{'place'} == $i) {
                                $existing->{$_}->{'place'} = $i;
                                $existing->{$_}->{'action'} = 'update' 
                                        unless $existing->{$_}->{'action'} eq 'insert';
                        }
                        $i++;
                } else {
                die Bric::Util::Fault::Exception::GEN->new(
                         { 'msg' => 'Improper Args to reorder contributors' });
                }
        }
        $self->_set( { '_contributors' => $existing });

        $self->_set__dirty($dirty);

        return $self;
}

################################################################################

=item my @ocs = $biz->get_output_channels

=item my $ocs_aref = $biz->get_output_channels

Returns a list or anonymous array of the output channels the business asset
will be output to when it is published.

B<Throws:>

=over 4

=item *

Bric::_get() - Problems retrieving fields.

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

=item *

Incorrect number of args to Bric::_set().

=item *

Bric::set() - Problems setting fields.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub get_output_channels { $get_oc_coll->(shift)->get_objs }

##############################################################################

=item $ba = $ba->add_output_channels(@ocs)

Adds output channels to the list of output channels to which this story will
be output upon publication.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Throws:>

=over 4

=item *

Bric::_get() - Problems retrieving fields.

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

=item *

Incorrect number of args to Bric::_set().

=item *

Bric::set() - Problems setting fields.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub add_output_channels {
    my $self = shift;
    my $oc_coll = $get_oc_coll->($self);
    $oc_coll->add_new_objs(@_);
    return $self;
}

##############################################################################

=item $biz = $biz->del_output_channels(@ocs)

=item $biz = $biz->del_output_channels(@oc_ids)

Removes output channels from this asset, so that it won't be output to these
output channels when it is published.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Throws:>

=over 4

=item *

Bric::_get() - Problems retrieving fields.

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

=item *

Incorrect number of args to Bric::_set().

=item *

Bric::set() - Problems setting fields.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub del_output_channels {
    my $self = shift;
    my $oc_coll = $get_oc_coll->($self);
    $oc_coll->del_objs(@_);
    return $self;
}

################################################################################

=item get_element_name()

Returns the name of the asset type that this is based on.   This is the same
as the name of the top level tile.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub get_element_name {
        my ($self) = @_;

        my $tile = $self->get_tile();

        my $name = $tile->get_name();

        return $name;
}

################################################################################

=item (@parts || $parts) = $biz->get_possible_data()

Returns the possible data that can be added to the top level tile of this
business asset based upon rules defined in asset type

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub get_possible_data {
        my ($self) = @_;

        my $tile = $self->get_tile();

        my $parts = $tile->get_possible_data();

        return wantarray ? @$parts : $parts;
}

################################################################################

=item (@containers || $containers) = $biz->get_possible_containers()

Returns the containers that are possible to add to the top level container
of this businesss asset

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub get_possible_containers {
    my ($self) = @_;
    my $tile = $self->get_tile();
    my $cont = $tile->get_possible_containers();
    return wantarray ? @$cont : $cont;
}

################################################################################

=item $self = $story->set_cover_date($cover_date)

Sets the cover date.

B<Throws:>

=over 4

=item *

Bric::_get() - Problems retrieving fields.

=item *

Unable to unpack date.

=item *

Unable to format date.

=item *

Incorrect number of args to Bric::_set().

=item *

Bric::set() - Problems setting fields.

=back

B<Side Effects:> 

NONE

B<Notes:> 

NONE

=cut

sub set_cover_date { $_[0]->_set(['cover_date'], [db_date($_[1])]) }

################################################################################

=item my $cover_date = $story->get_cover_date($format)

Returns cover date.

B<Throws:>

=over 4

=item *

Bric::_get() - Problems retrieving fields.

=item *

Unable to unpack date.

=item *

Unable to format date.

=back

B<Side Effects:> 

NONE

B<Notes:> 

NONE

=cut

sub get_cover_date { local_date($_[0]->_get('cover_date'), $_[1]) }

################################################################################

=item $self = $story->set_publish_date($publish_date)

Sets the publish date.

B<Throws:>

=over 4

=item *

Bric::_get() - Problems retrieving fields.

=item *

Unable to unpack date.

=item *

Unable to format date.

=item *

Incorrect number of args to Bric::_set().

=item *

Bric::set() - Problems setting fields.

=back

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub set_publish_date { $_[0]->_set(['publish_date'], [db_date($_[1])]) }

################################################################################

=item my $publish_date = $story->get_publish_date($format)

Returns publish date.

B<Throws:>

=over 4

=item *

Bric::_get() - Problems retrieving fields.

=item *

Unable to unpack date.

=item *

Unable to format date.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub get_publish_date { local_date($_[0]->_get('publish_date'), $_[1]) }

################################################################################

=item (@objs || $objs) = $asset->get_related_objects

Return all the related story or media objects for this business asset.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub get_related_objects {
    my $self = shift;

    return $self->_find_related($self->get_tile);
}

sub _find_related {
    my $self = shift;
    my ($tile) = @_;
    my @children = $tile->get_containers;
    my (@related);

    # Add this tiles related assets
    my $rmedia = $tile->get_related_media;
    my $rstory = $tile->get_related_story;
    push @related, $rmedia if $rmedia;
    push @related, $rstory if $rstory;

    # Check all the children for related assets.
    foreach my $c (@children) {
        my @r = $self->_find_related($c);

        push @related, @r if @r;
    }

    return (wantarray ? @related : \@related) if @related;
    return;
}

################################################################################

=item $container_tile = $ba->get_tile()

Returns the top level tile that coresponds to this Asset

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub get_tile {
    my ($self) = @_;
    my $tile = $self->_get('_tile');
    unless ($tile) {
        ($tile) = Bric::Biz::Asset::Business::Parts::Tile::Container->list(
          { object    => $self,
            parent_id => undef,
            active    => 1 });
        $self->_set( { '_tile' => $tile });
    }
    return $tile;
}

################################################################################

=item $uri = $biz->get_primary_uri

Returns the primary URL for this business asset. The primary URL is determined
by the pre- and post- directory strings of the primary output channel, the
URI of the business object's asset type, and the cover date if the asset type
is not a fixed URL.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub get_primary_uri {
    my $self = shift;
    my $uri = $self->_get('primary_uri');

    unless ($uri) {
        $uri = $self->get_uri;
        $self->_set(['primary_uri'], [$uri]);
    }
    return $uri;
}

################################################################################

=item ($tiles || @tiles) = $biz->get_tiles()

Returns the tiles that are held with in the top level tile of this business
asset. Convenience shortcut to C<< $ba->get_tile->get_tiles >>.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub get_tiles {
    my $self = shift;
    $self->get_tile->get_tiles;
}

###############################################################################

=item $ba = $ba->add_data( $atd_obj, $data )

This will create a tile and add it to the container. Convenience shortcut to
C<< $ba->get_tile->add_data >>.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub add_data {
    my $self = shift;
    $self->get_tile->add_data(@_);
}

###############################################################################

=item $new_container = $ba->add_container( $atc_obj )

This will create and return a new container tile that is added to the current
container. Convenience shortcut to C<< $ba->get_tile->add_container >>.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub add_container {
    my $self = shift;
    $self->get_tile->add_container(@_);
}

###############################################################################

=item $data = $ba->get_data( $name, $obj_order )

=item $data = $ba->get_data( $name, $obj_order, $format )

Returns the data of a given name and object order. Convenience shortcut to
C<< $ba->get_tile->get_data >>.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub get_data {
    my $self = shift;
    $self->get_tile->get_data(@_);
}

###############################################################################

=item $container = $ba->get_container( $name, $obj_order )

Returns a container object of the given name that falls at the given object
order position. Convenience shortcut to C<< $ba->get_tile->get_container >>.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub get_container {
    my $self = shift;
    $self->get_tile->get_container(@_);
}

###############################################################################

=item $asset = $asset->add_keywords(\@keywords)

Adds the given keywords to the asset.  Accepts keyword objects or
keyword object ids.

B<Throws:> NONE

B<Side Effects:> NONE

B<Notes:> NONE

=cut


sub add_keywords {
    my ($self, $keywords) = @_;
    my $keyword;

    foreach my $k (@$keywords) {
        # find object for id
        if (ref $k) {
            $keyword = $k;
        } else {
            $keyword = Bric::Biz::Keyword->lookup({id => $k});
            die Bric::Util::Fault::Exception::GEN->new(
                 { msg => "No keyword object found for id '$k'" } )
              unless defined $keyword;
        }
        
        # associate keyword with this asset
        $keyword->associate($self);
    }

    return $self;
}

###############################################################################

=item $kw_aref || @kws = $asset->get_keywords()

Returns an array ref or an array of keyword objects, assigned to this
Business Asset.

B<Throws:> NONE

B<Side Effects:> NONE

B<Notes:> NONE

=cut

sub get_keywords {
    my $self = shift;
    return Bric::Biz::Keyword->list({ object => $self });
}

###############################################################################

=item $kw_aref || @kws = $asset->get_all_keywords()

Returns an array ref or an array of keyword objects assigned to this Business
Asset and to its categories.

B<Throws:> NONE

B<Side Effects:> NONE

B<Notes:> NONE

=cut

sub get_all_keywords {
    my $self = shift;
    my %kw = map { ($_->get_id, $_) } 
      ( Bric::Biz::Keyword->list({ object => $self }), 
        _get_category_keywords() );
    my @kw = sort { lc $a->get_sort_name cmp lc $b->get_sort_name }
      values %kw;

    return wantarray ? @kw : \@kw;
}

=item $asset = $asset->delete_keywords([$kw]);

Takes a list of keywords and disassociates them from the object.
Category keywords can not be disassociated from the asset.  

B<Throws:> NONE

B<Side Effects:> NONE

B<Notes:> NONE

=cut

sub delete_keywords {
    my ($self,$keywords) = @_;
    
    my $keyword;
    foreach my $k (@$keywords) {
        # find object for id
        if (ref $k) {
            $keyword = $k;
        } else {
            $keyword = Bric::Biz::Keyword->lookup({id => $k});
            die Bric::Util::Fault::Exception::GEN->new(
                 { msg => "No keyword object found for id '$k'" } )
              unless defined $keyword;
        }
        
        # dissociate keyword with this asset
        $keyword->dissociate($self);
    }

    return $self;
}

###############################################################################


=item ($self || undef) = $ba->has_keyword($keyword)

Returns true is the keyword object is associated with this asset.

=cut

sub has_keyword {
    my ($self,$keyword) = @_;
    my $keyword_id = $keyword->get_id;
    my @keywords = $self->get_keywords();
    return $self if grep { $keyword_id == $_->get_id } @keywords;
    return;
}

###############################################################################

=item $self = $self->cancel()

Called upon a checked out asset.   This unchecks it out.

B<Throws:>

"Can not cancel a non checked out asset"

B<Side Effects:>

This will remove the coresponding object from the database

B<Notes:>

NONE

=cut

sub cancel {
        my ($self) = @_;

        # the user has decided to uncheck this out.
        # this will result in a delete from the data base of this 
        # row

        if ( not defined $self->_get('user_id')) {
                # this is not checked out, it can not be deleted
                die Bric::Util::Fault::Exception::GEN->new( {
                        msg => "Can not cancel a non checked out asset" });
        }

        $self->_set( { '_delete' => 1});
}

################################################################################

=item ($ba || undef) = $ba->is_current()

Return whether this is the most current version or not.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub is_current {
        my ($self) = @_;

        return ($self->_get('current_version') == $self->_get('version'))
                ? $self : undef;
}

################################################################################

=item = $biz = $biz->checkout( { user__id => $user_id })

checks out the asset to the specified user

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub checkout {
        my ($self, $param) = @_;

        # make sure that this version is the most current
        unless ($self->_get('version') == $self->_get('current_version') ) {
                die Bric::Util::Fault::Exception::GEN->new( { msg =>
                        "Unable to checkout old_versions" });
        }
        # Make sure that the object is not already checked out
        if (defined $self->_get('user__id')) {
                die Bric::Util::Fault::Exception::GEN->new( {
                        msg => "Already Checked Out" });
        }
        unless (defined $param->{'user__id'}) {
                die Bric::Util::Fault::Exception::GEN->new( { msg =>
                        "Must be checked out to users" });
        }

        my $tile = $self->get_tile();
        $tile->prepare_clone();

        my $contribs = $self->_get_contributors();
        # clone contributors
        foreach (keys %$contribs ) {
                $contribs->{$_}->{'action'} = 'insert';
        }

        # Clone output channels.
        my $oc_coll = $get_oc_coll->($self);
        my @ocs = $oc_coll->get_objs;
        $oc_coll->del_objs;
        $oc_coll->add_new_objs(@ocs);

        $self->_set( {
                user__id => $param->{'user__id'} ,
                modifier => $param->{'user__id'},
                version_id => undef,
                checked_out => 1
        });

        $self->_set( { '_update_contributors' => 1 }) if $contribs;

        return $self;
}

################################################################################

=item $ba = $ba->save()

Commits the changes to the database

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub save {
    my $self = shift;

    my ($related_obj, $tile, $oc_coll, $ci, $co, $vid) =
      $self->_get(qw(_related_grp_obj _tile _oc_coll _checkin _checkout
                     version_id));

    if ($co) {
        $tile->prepare_clone;
        $self->_set(['_checkout'], []);
    }

    # Is this necessary? Seems kind of pointless. [David 2002-09-19]
    $self->_set(['_checkin'], []) if $ci;

    $self->_sync_attributes;

    if ($tile) {
        $tile->set_object_instance_id($vid);
        $tile->save;
    }

    $related_obj->save if $related_obj;
    $self->_sync_contributors;
    $oc_coll->save($self->key_name => $vid) if $oc_coll;
    $self->SUPER::save;
    $self->_set__dirty(0);
}

###############################################################################

#=============================================================================#

=back

=head2 PRIVATE

=cut

#--------------------------------------#

=head2 Private Class Methods

=over 4

=item $self = $self->_init()

Preforms functions needed to create new business assets

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub _init {
    my ($self, $init) = @_;

    die Bric::Util::Fault::Exception::GEN->new(
      {msg => "Method not implemented"}) unless ref $self;

    die Bric::Util::Fault::Exception::GEN->new(
      { msg => "Cannot create an asset without an Element"})
      unless $init->{element__id} || $init->{element};

    die Bric::Util::Fault::Exception::GEN->new( {
      msg => "Can not create asset with out Source "})
      unless $init->{'source__id'};

    if ($init->{'cover_date'}) {
        $self->set_cover_date( $init->{'cover_date'} );
        delete $init->{'cover_date'};
        my $source = Bric::Biz::Org::Source->lookup
          ({id => $init->{'source__id'}});
        if (my $expire = $source->get_expire) {
            # add the days to the cover date and set the expire date
            my $date = local_date($self->_get('cover_date'), 'epoch');
            my $new_date = $date + ($expire * 24 * 60 * 60);
            $new_date = strfdate($new_date);
            $new_date = db_date($new_date);
            $self->_set( { expire_date => $new_date });
        }
    }

    # Get the element object.
    if ($init->{element}) {
        $init->{element__id} = $init->{element}->get_id;
    } else {
        $init->{element} =
          Bric::Biz::AssetType->lookup({ id => $init->{element__id}});
    }

    # Set up the output channels.
    $self->add_output_channels( map { $_->is_enabled ? $_ : () }
                                $init->{element}->get_output_channels);

    # Let's create the new tile as well.
    my $tile = Bric::Biz::Asset::Business::Parts::Tile::Container->new
      ({ object     => $self,
         element_id => $init->{element__id},
         element    => $init->{element}
       });

    $self->_set([qw(version current_version checked_out _tile modifier
                    element__id _element_object publish_status)],
                [0, 0, 1, $tile, @{$init}{qw(user__id element__id element)},
                 0]);

    $self->_set__dirty;
}

###############################################################################


#--------------------------------------#

=back

=head2 Private Instance Methods

=over 4

=item $at_obj = $self->_construct_uri()

Returns URI contructed from the output chanel paths, categories and the date.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub _construct_uri {
    my $self = shift;
    my ($cat_obj, $oc_obj) = @_;
#   my $cat_obj = $self->get_primary_category();
    my $element_obj = $self->_get_element_object();
    my $fu = $element_obj->get_fixed_url;
    my ($pre, $post);

    # Get the pre and post values.
    ($pre, $post) = ($oc_obj->get_pre_path, $oc_obj->get_post_path) if $oc_obj;

    # Add the pre value.
    my @path = ('', defined $pre ? $pre : ());

    # Get URI Format.
    my $fmt = $fu ? $oc_obj->get_fixed_uri_format : $oc_obj->get_uri_format;

    my @tokens = split( '/', $fmt );

    # iterate over tokens pushing each onto @path
    foreach my $token( @tokens ) {
        next unless $token;
        if( $uri_format_hash{$token}  ne '' ) {
            # Add the cover date value.
            push @path, $self->get_cover_date( $uri_format_hash{ $token } );
        } else {
            if( $token eq 'categories' ) {
                # Add Category
                push @path, $cat_obj->ancestry_path if $cat_obj;
            } elsif( $token eq 'slug' ) {
                # Add the slug.
                push @path, $self->get_slug if $self->key_name eq 'story';
            }
        }
    }

    # Add the post value.
    push @path, $post if $post;

    # Return the URI with the case adjusted as necessary.
    my $uri_case = $oc_obj->get_uri_case;
    if( $uri_case eq LOWERCASE ) {
        return lc Bric::Util::Trans::FS->cat_uri(@path);
    } elsif( $uri_case eq UPPERCASE ) {
        return uc Bric::Util::Trans::FS->cat_uri(@path);
    } else {
        return Bric::Util::Trans::FS->cat_uri(@path);
    }
}

###############################################################################

=item $at_obj = $self->_get_element_object()

Returns the asset tpe object that coresponds to this business object

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub _get_element_object {
    my ($self) = @_;

        my $dirty = $self->_get__dirty();

    my $at_obj = $self->_get('_element_object');
    return $at_obj if $at_obj;
    $at_obj = Bric::Biz::AssetType->lookup({ id => $self->_get('element__id')});
    $self->_set(['_element_object'], [$at_obj]);

        $self->_set__dirty($dirty);
    return $at_obj;
}

################################################################################

=item $self = $self->_sync_contributors()

Syncs the contributors for this story

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub _sync_contributors {
    my $self = shift;
    return $self unless $self->_get('_update_contributors');

    my $contribs = $self->_get_contributors();
    my ($del_contribs, $vid) = $self->_get(qw(_del_contrib version_id));

    foreach (keys %$del_contribs) {
        $self->_delete_contributor($_);
        delete $del_contribs->{$_};
    }

    foreach my $id (keys %$contribs) {
        my $role = $contribs->{$id}->{'role'};
        my $place = $contribs->{$id}->{'place'};
        if ($contribs->{$id}->{'action'} eq 'insert') {
            $self->_insert_contributor($id, $role, $place);
        } elsif ($contribs->{$id}->{'action'} eq 'update') {
            $self->_update_contributor($id, $role, $place);
        }
        delete $contribs->{$id}->{'action'};
    }

    $self->_set( {
                  '_del_contrib'        => $del_contribs,
                  '_update_contributors' => undef,
                  '_contributors' => $contribs
                 });

    return $self;
}

################################################################################

=item $cat_keywords = $ba->_get_category_keywords();

Returns the keywords that are associated with the categories that this asset 
is associated with 

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub _get_category_keywords {
        my ($self) = @_;

        my $categories = $self->_get('_categories');

        my %keywords;
        foreach my $c_id (keys %$categories) {

                my $cat;
                if ($categories->{$c_id}->{'object'}) {
                        $cat = $categories->{$c_id}->{'object'};
                } else {
                        $cat = Bric::Biz::Category->lookup({ id => $c_id });
                        $categories->{$c_id}->{'object'} = $cat;
                }

                my $kw_list = $cat->keywords();
                foreach (@$kw_list) {
                        my $kw_id = $_->get_id();
                        $keywords{$kw_id} = $_;
                }
        }

        my @list = sort { lc $a->get_sort_name cmp lc $b->get_sort_name }
          values %keywords;

        return wantarray ? @list : \@list;
}

###############################################################################

=back

=head2 Private Functions

=over 4

=item my $oc_coll = $get_oc_coll->($ba)

Returns the collection of output channels for this asset.
L<Bric::Util::Coll::OutputChannel|Bric::Util::Coll::OutputChannel>
object. See that class and its parent, L<Bric::Util::Coll|Bric::Util::Coll>,
for interface details.

B<Throws:>

=over 4

=item *

Bric::_get() - Problems retrieving fields.

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

=item *

Incorrect number of args to Bric::_set().

=item *

Bric::set() - Problems setting fields.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

$get_oc_coll = sub {
    my $self = shift;
    my $dirt = $self->_get__dirty;
    my ($id, $oc_coll) = $self->_get('version_id', '_oc_coll');
    return $oc_coll if $oc_coll;
    $oc_coll = Bric::Util::Coll::OutputChannel->new
      (defined $id ? {$self->key_name . '_instance_id' => $id} : undef);
    $self->_set(['_oc_coll'], [$oc_coll]);
    $self->_set__dirty($dirt); # Reset the dirty flag.
    return $oc_coll;
};

1;

__END__

=back

=head1 NOTES

NONE

=head1 AUTHOR

michael soderstrom <miraso@pacbell.net>

=head1 SEE ALSO

L<Bric>, L<Bric::Biz::Asset>

=cut

