package Bric::Util::Grp::Desk;
###############################################################################

=head1 NAME

Bric::Util::Grp::Desk - A class to impliment desk groups

=head1 VERSION

$Revision: 1.8 $

=cut

our $VERSION = (qw$Revision: 1.8 $ )[-1];

=head1 DATE

$Date: 2003-03-11 16:23:52 $

=head1 SYNOPSIS

 use Bric::Util::Grp::Desk;

 # Create a new keyword synonym object.
 my $desk_grp  = new Bric::Util::Grp::Desk();

 # Add a description for this synonym group.
 $desc    = $desk_grp->get_description($desc);

=head1 DESCRIPTION

Impliments groups of desks.

=cut

#==============================================================================#
# Dependencies                         #
#======================================#

#--------------------------------------#
# Standard Dependencies                 

use strict;

#--------------------------------------#
# Programatic Dependencies              
 


#==============================================================================#
# Inheritance                          #
#======================================#

use base qw( Bric::Util::Grp );

#=============================================================================#
# Function Prototypes                  #
#======================================#



#==============================================================================#
# Constants                            #
#======================================#

use constant PACKAGE => 'Bric::Biz::Workflow::Parts::Desk';
use constant CLASS_ID => 40;
use constant OBJECT_CLASS_ID => 45;

#==============================================================================#
# Fields                               #
#======================================#

#--------------------------------------#
# Public Class Fields                   



#--------------------------------------#
# Private Class Fields                  



#--------------------------------------#
# Instance Fields                       

# This method of Bricolage will call 'use fields' for you and set some permissions.
BEGIN {
    Bric::register_fields({
			 # Public Fields

			 # Private Fields
			 
			});
}

#==============================================================================#

=head1 INTERFACE

=head2 Constructors

=over 4

=cut

#--------------------------------------#
# Constructors                          

#------------------------------------------------------------------------------#

=item $obj = new Bric::Util::Grp::Desk($init);

Creates a new desk group.  Uses inherited 'new' method.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

#------------------------------------------------------------------------------#

=item @objs = lookup Bric::Util::Grp::Desk($param);

Uses inherited 'lookup' method.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

#------------------------------------------------------------------------------#

=item @objs = list Bric::Util::Grp::Desk($param);

Uses inherited 'list' method.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=back

=head2 Destructors

=cut

sub DESTROY {
    # This method should be here even if its empty so that we don't waste time
    # making Bricolage's autoload method try to find it.
}

#--------------------------------------#

=head2 Public Class Methods

NONE.

=head2 Public Instance Methods

=over 4

=item $class_id = Bric::Util::Grp::Category->get_class_id()

This will return the class id that this group is associated with
it should have an id that maps to the class object instance that is
associated with the class of the grp ie Bric::Util::Grp::AssetVersion

B<Throws:>
NONE

B<Side Effects:>
NONE

B<Notes:>

Overwite this in your sub classes

=cut

sub get_class_id {
    return CLASS_ID;
}

#------------------------------------------------------------------------------#

=item $h = $key->get_supported_classes;

This supplies a package to table name mapping.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub get_supported_classes {
    return { &PACKAGE => 'desk' };
}	

################################################################################

=item $class_id = Bric::Util::Grp::Desk->get_object_class_id

Forces all Objects to be considered as this class.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub get_object_class_id { OBJECT_CLASS_ID }

#==============================================================================#

=back

=head2 Private Methods

NONE.

=head2 Private Class Methods

NONE

=head2 Private Instance Methods

NONE

=cut

1;
__END__

=head1 NOTES

NONE

=head1 AUTHOR

Garth Webb <garth@perijove.com>

=head1 SEE ALSO

L<perl>, L<Bric>, L<Bric::Biz::Workflow::Parts::Desk>

=cut
