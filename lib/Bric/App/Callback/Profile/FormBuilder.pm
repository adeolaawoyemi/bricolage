package Bric::App::Callback::Profile::FormBuilder;

use base qw(Bric::App::Callback Bric::App::Callback::Profile );
__PACKAGE__->register_subclass;
use constant CLASS_KEY => 'formBuilder';

use strict;
use Bric::App::Authz qw(:all);
use Bric::App::Event qw(log_event);
use Bric::App::Session qw(:user);
use Bric::App::Util qw(:aref :msg :history :pkg :browser);
use Bric::Biz::AssetType::Parts::Data;
use Bric::Biz::OutputChannel;
use Bric::Biz::OutputChannel::Element;
use Bric::Biz::Site;

my %meta_props = (
    'disp'      => 'fb_disp',
    'value'     => 'fb_value',
    'type'      => 'fb_type',
    'length'    => 'fb_size',
    'size'      => 'fb_size',
    'maxlength' => 'fb_maxlength',
    'rows'      => 'fb_rows',
    'cols'      => 'fb_cols',
    'multiple'  => 'fb_allowMultiple',
    'vals'      => 'fb_vals',
    'pos'       => 'fb_position',
);

my %conf = (
    'contrib_type' => {
        'disp_name' => 'Contributor Type',
    },
    'element' => {
        'disp_name' => 'Element',
    },
);

my ($base_handler, $do_contrib_type, $do_element, $clean_param,
    $delete_ocs, $delete_sites, $check_save_element, $get_obj,
    $set_key_name, $update_element_attrs, $get_data_href,
    $delete_element_attrs, $set_primary_ocs, $add_new_attrs,
    $save_element_etc);


sub save : Callback {
    return unless $_[0]->value;      # already handled
    &$base_handler;
}
sub add : Callback {
    return unless $_[0]->value;      # already handled
    &$base_handler;
}
sub save_n_stay : Callback {
    return unless $_[0]->value;      # already handled
    &$base_handler;
}
sub addElement : Callback {
    return unless $_[0]->value;      # already handled
    &$base_handler;
}
sub add_oc_id : Callback {
    return unless $_[0]->value;      # already handled
    &$base_handler;
}
sub add_site_id : Callback {
    return unless $_[0]->value;      # already handled
    &$base_handler;
}

###

$base_handler = sub {
    my $self = shift;
    my $param = $self->params;

    my $key = (parse_uri($self->apache_req->uri))[2];
    my $class = get_package_name($key);

    # Instantiate the object.
    my $id = $param->{$key . '_id'};
    my $obj = defined $id ? $class->lookup({ id => $id }) : $class->new;

    # Check the permissions.
    unless (chk_authz($obj, $id ? EDIT : CREATE, 1)) {
        # If we're in here, the user doesn't have permission to do what
        # s/he's trying to do.
        add_msg("Changes not saved: permission denied.");
        $self->set_redirect(last_page());
    } else {
        # Process its data
        my $name = $param->{'name'};
        my $disp_name = $conf{$key}{'disp_name'};

        if ($param->{'delete'}) {
            $obj->deactivate();
            $obj->save();
            add_msg("$disp_name profile \"[_1]\" deleted.", $name);
            log_event("${key}_deact", $obj);
            $self->set_redirect("/admin/manager/$key");
        } else {
            if ($key eq 'contrib_type') {
                $param->{'obj'} = $do_contrib_type->($self, $obj, $key, $class);
            } elsif ($key eq 'element') {
                $param->{'obj'} = $do_element->($self, $obj, $key, $class);
            }
        }
    }
};

$do_contrib_type = sub {
    my ($self, $obj, $key, $class) = @_;
    my $param = $self->params;
    my $name = $param->{'name'};
    my $disp_name = $conf{$key}{'disp_name'};
    my %del_attrs = map( {$_ => 1} @{ mk_aref($param->{'delete_attr'})} );
    my $key_name = exists($param->{'key_name'})
      ? $param->{'key_name'}
      : '';

    $obj->activate();
    $obj->set_name($param->{'name'});
    $obj->set_description($param->{'description'});

    my $data_href = $obj->get_member_attr_hash || {};
    $data_href = { map { lc($_) => 1 } keys %$data_href };

    # Update existing attributes.
    my $i = 0;
    my $pos = mk_aref($param->{attr_pos});
    foreach my $aname (@{ mk_aref($param->{attr_name}) } ) {
        next if $del_attrs{$aname};

        $obj->set_member_attr({ name => $aname,
                                sql_type => $obj->get_member_attr_sql_type
                                            ({ name => $aname}),
                                value => $param->{"attr|$aname"} });
        $obj->set_member_meta({ name => $aname,
                                field => 'pos',
                                value => $pos->[$i] });
        ++$i;
    }
    my $no_save;
    # Add in any new attributes.
    if ($param->{fb_name}) {
        # There's a new attribute. Decide what type it is.
        if ($data_href->{lc $param->{fb_name}}) {
            # There's already an attribute by that name.
            add_msg("An \"[_1]\" attribute already exists. Please try another name.", $param->{fb_name});
            $no_save = 1;
        } else {
            my $sqltype = $param->{fb_type} eq 'date' ? 'date'
              : $param->{fb_type} eq 'textarea'
              && (!$param->{fb_maxlength} || $param->{fb_maxlength} > 1024)
              ? 'blob' : 'short';

            my $value = $sqltype eq 'date' ? undef : $param->{fb_value};

            # Set it for all members of this group.
            $obj->set_member_attr({ name => $param->{fb_name},
                                    sql_type => $sqltype,
                                    value => $value
                                  });

            $param = $clean_param->($param);

            # Record the metadata so we can properly display the form element.
            while (my ($k, $v) = each %meta_props) {
                $obj->set_member_meta({ name => $param->{fb_name},
                                        field => $k,
                                        value => $param->{$v} });
            }
            # Log that we've added it.
            log_event("${key}_ext", $obj, { 'Name' => $param->{fb_name} });
        }
    }

    # Delete any attributes that are no longer needed.
    if ($param->{delete_attr}) {
        foreach my $attr (keys %del_attrs) {
            $obj->delete_member_attr({ name => $attr });
            # Log that we've deleted it.
            log_event("${key}_unext", $obj, { 'Name' => $attr });
        }
    }

    # Save the group
    unless ($no_save) {
        $obj->save();

        # Take care of group management.
        $self->manage_grps($obj) if $param->{add_grp} || $param->{rem_grp};

        if ($self->cb_key eq 'save') {
            # Record a message and redirect if we're saving.
            add_msg("$disp_name profile \"[_1]\" saved.", $name);
            # Log it.
            my $msg = defined $param->{"$key\_id"} ? "$key\_save" : "$key\_new";
            log_event($msg, $obj);
            # Redirect back to the manager.
            $self->set_redirect("/admin/manager/$key");
        }
    }

    # Grab the ID.
    $param->{"$key\_id"} ||= $obj->get_id;
};

$do_element = sub {
    my ($self, $obj, $key, $class) = @_;
    my $param = $self->params;
    my $name = $param->{'name'};
    my $disp_name = $conf{$key}{'disp_name'};
    my %del_attrs = map( {$_ => 1} @{ mk_aref($param->{'delete_attr'})} );
    my $key_name = exists($param->{'key_name'})
      ? $param->{'key_name'}
      : '';
    my $widget = $self->class_key;
    my $cb_key = $self->cb_key;

    # Make sure the name isn't already in use.
    my $no_save;
    # AssetType has been updated to take an existing but undefined 'active'
    # flag as meaning, "list both active and inactive"
    my @cs = $class->list_ids({key_name => $param->{key_name},
                               active   => undef});

    # Check if we need to inhibit a save based on some special conditions
    $no_save = $check_save_element->(\@cs, $param, $key);

    add_msg("The key name \"[_1]\" is already used by another $disp_name.",
            $key_name)
      if $no_save;

    # Roll in the changes.
    $obj = $get_obj->($class, $param, $key, $obj);
    $obj->activate();
    $obj->set_name($param->{'name'});   # must come after $get_obj !

    $set_key_name->($obj, $param) unless $no_save;
    $obj->set_description($param->{'description'});
    $obj->set_burner($param->{burner}) if defined $param->{burner};

    # side-effect: returns enabled-OCs hashref.
    # pass in ref to $no_save...
    my $enabled = $set_primary_ocs->($self, $obj, \$no_save);

    my $data_href = $get_data_href->($param, $key);

    $update_element_attrs->(\%del_attrs, $param, $data_href);

    $add_new_attrs->($self, $obj, $key, $data_href, \$no_save);
    $delete_element_attrs->($obj, $param, $key, $cb_key, \%del_attrs, $data_href);

    $delete_ocs->($obj, $param);
    $delete_sites->($obj, $param, $self);

    # Enable output channels.
    foreach my $oc ($obj->get_output_channels) {
        $enabled->{$oc->get_id} ? $oc->set_enabled_on : $oc->set_enabled_off;
    }

    # Add output channels.
    $obj->add_output_channel($self->value) if $cb_key eq 'add_oc_id';

    # Add sites
    if ($cb_key eq 'add_site_id') {
        my $site_id = $self->value;
        # Only add the site if it has associated output channels.
        if (Bric::Biz::OutputChannel->list({ site_id => $site_id })->[0]) {
            $obj->add_site($site_id);
        } else {
            add_msg 'Site "[_1]" cannot be associated because it has no ' .
              'output channels',
              Bric::Biz::Site->lookup({ id => $site_id })->get_name;
        }
    }

    # delete any selected sub elements
    if ($param->{"$key|delete_sub"}) {   # note: not a callback
        $obj->del_containers(mk_aref($param->{"$key|delete_sub"}));
    }

    # If it is a new element and top level we must add a site
    if ($param->{isNew} && $obj->get_top_level) {
        # Try to get the primary site
        if (my $site_id = $self->cache->get_user_cx(get_user_id())) {
            if (Bric::Biz::OutputChannel->list({ site_id => $site_id })->[0]) {
                $obj->add_site($site_id);
            } else {
                add_msg 'Site "[_1]" cannot be associated because it has ' .
                  'no output channels',
                  Bric::Biz::Site->lookup({ id => $site_id })->get_name;
            }
        } else {
            # Else we must do it some other way!
            my @sites = Bric::Biz::Site->list();
            $obj->add_site($sites[0]);
        }
    }

    # Take care of group management.
    $self->manage_grps($obj) if $param->{add_grp} || $param->{rem_grp};

    $save_element_etc->($self, $obj, $key, $no_save, $disp_name, $name);

    return $obj;
};


$clean_param = sub {
    my $param = shift;

    # Clean any select/radio values.
    if ($param->{fb_vals}) {
        $param->{fb_vals} =~ s/\r/\n/g;
        $param->{fb_vals} =~ s/\n{2,}/\n/g;
        $param->{fb_vals} =~ s/\s*,\s*/,/g;
        my $tmp;
        foreach my $line (split /\n/, $param->{fb_vals}) {
            $tmp .= $line =~ /,/ ? "$line\n" : "$line,$line\n";
        }
        $param->{fb_vals} = $tmp;
    }

    return $param;
};

$delete_ocs = sub {
    my ($obj, $param) = @_;

    # Delete output channels.
    if ($param->{'rem_oc'}) {
        my $del_oc_ids = mk_aref($param->{'rem_oc'});
        $obj->delete_output_channels($del_oc_ids);
    }
};

$delete_sites = sub {
    my ($obj, $param, $self) = @_;

    # Delete sites.
    if ($param->{'rem_site'}) {
        my $del_site_ids = mk_aref($param->{'rem_site'});
        if(@$del_site_ids >= @{$obj->get_sites}) {
            add_msg("You cannot remove all Sites.");
        } else {
            $obj->remove_sites($del_site_ids);
        }
    }
};

$check_save_element = sub {
    my ($cs, $param, $key) = @_;

    my $no_save = 0;

    if    (@$cs > 1)                                   { $no_save = 1 }
    elsif (@$cs == 1 && !defined $param->{element_id}) { $no_save = 1 }
    elsif (@$cs == 1 && defined $param->{element_id}
           && $cs->[0] != $param->{element_id})        { $no_save = 1 }

    return $no_save;
};

$get_obj = sub {
    my ($class, $param, $key, $obj) = @_;

    # Create a new object if we need to pass in an Element Type ID
    $obj = $class->new({ type__id => $param->{"$key\_type_id"} })
      if exists $param->{"$key\_type_id"} && !defined $param->{"$key\_id"};

    return $obj;
};

$set_key_name = sub {
    my ($obj, $param) = @_;

    # Normalize the key name
    my $kn = lc($param->{key_name});
    $kn =~ y/a-z0-9/_/cs;

    $obj->set_key_name($kn);
};

$update_element_attrs = sub {
    my ($del_attrs, $param, $data_href) = @_;

    # Update existing attributes.
    my $pos = mk_aref($param->{'attr_pos'});
    my $i = 0;
    foreach my $aname (@{ mk_aref($param->{'attr_name'}) }) {
        unless ($del_attrs->{$aname}) {
            my $field = lc $aname;
            $data_href->{$field}->set_place($pos->[$i]);
            $data_href->{$field}->set_meta('html_info', 'pos', $pos->[$i]);
            $data_href->{$field}->set_meta('html_info', 'value',
                                           $param->{"attr|$aname"});
            $data_href->{$field}->save;
            $i++;
        }
    }
};

$get_data_href = sub {
    my ($param, $key) = @_;

    # Get existing attrs from the Parts::Data class rather than from
    # $obj->get_data so that we can be sure to check for both active
    # and inactive data fields.
    my $all_data = Bric::Biz::AssetType::Parts::Data->list(
      { element__id => $param->{"$key\_id"} });
    my $data_href = { map { lc ($_->get_key_name) => $_ } @$all_data };
    return $data_href;
};

$delete_element_attrs = sub {
    my ($obj, $param, $key, $cb_key, $del_attrs, $data_href) = @_;

    # Delete any attributes that are no longer needed.
    if ($param->{delete_attr} && ($cb_key eq 'save' || $cb_key eq 'save_n_stay')) {
        my $del = [];
        foreach my $attr (keys %$del_attrs) {
            my $atd = $data_href->{lc $attr};
            push @$del, $atd;
            log_event("$key\_attr_del", $obj, { Name => $attr });
            log_event("$key\_data_del", $atd);
        }
        $obj->del_data($del);
    }
};

$set_primary_ocs = sub {
    my ($self, $obj, $no_save) = @_;    # $no_save is a scalar ref
    my $param = $self->params;
    my $cb_key = $self->cb_key;

    # Determine the enabled output channels.
    my %enabled = map { $_ ? ( $_ => 1) : () } @{ mk_aref($param->{enabled}) },
      map { $obj->get_primary_oc_id($_) } $obj->get_sites;

    # Set the primary output channel ID per site
    if (($cb_key eq 'save' || $cb_key eq 'save_n_stay') && $obj->get_top_level) {
        my %oc_ids;
        @oc_ids{map { $_->get_id } $obj->get_sites} = ();

        foreach my $field (keys %$param) {
            next unless $field =~ /^primary_oc_site_(\d+)$/;
            my $siteid = $1;
            $obj->set_primary_oc_id($param->{$field}, $siteid);
            my ($oc) = $obj->get_output_channels($param->{$field});
            unless ($oc) {
                $obj->add_output_channel($param->{$field});
                $oc = Bric::Biz::OutputChannel->lookup({ id => $param->{$field} });
            }

            # Associate it with the site and make sure it's enabled.
            $oc_ids{$siteid} = $param->{$field};
            $enabled{$oc->get_id} = 1;
        }

        foreach my $siteid (keys %oc_ids) {
            unless ($oc_ids{$siteid}) {
                $$no_save = 1;
                my $site = Bric::Biz::Site->lookup({id => $siteid});
                add_msg('Site "[_1]" requires a primary output channel.',
                        $site->get_name);
            }
        }
    } elsif ($cb_key eq 'add_oc_id') {
        my $oc = Bric::Biz::OutputChannel::Element->lookup({id => $self->value});
        my $siteid = $oc->get_site_id;
        unless ($obj->get_primary_oc_id($siteid)) {
            # They're adding the first one. Make it the primary.
            $obj->set_primary_oc_id($self->value, $siteid);
        }
    }

    return \%enabled;
};

$add_new_attrs = sub {
    my ($self, $obj, $key, $data_href, $no_save) = @_;   # $no_save scalar_ref
    my $param = $self->params;

    # Add in any new attributes.
    if ($param->{fb_name}) {
        (my $key_name = lc $param->{fb_name}) =~ y/a-z0-9/_/cs;
        # There's a new attribute. Decide what type it is.
        if ($data_href->{$key_name}) {
            # There's already an attribute by that name.
            add_msg('An "[_1]" attribute already exists. Please try another name.', $key_name);
            $$no_save = 1;
        } else {
            my $sqltype = $param->{'fb_type'} eq 'date' ? 'date'
              : $param->{'fb_type'} eq 'textarea'
              && (!$param->{'fb_maxlength'} || $param->{'fb_maxlength'} > 1024)
              ? 'blob' : 'short';

            my $value = $sqltype eq 'date' ? undef : $param->{'fb_value'};

            $param = $clean_param->($param);
            my $max = $param->{'fb_maxlength'} ? $param->{'fb_maxlength'}
              : ($param->{'fb_maxlength'} eq '0') ? 0 : undef;

            my $atd = $obj->new_data({ key_name    => $key_name,
                                       required    => $param->{fb_req} ? 1 : 0,
                                       quantifier  => $param->{fb_quant} ? 1 : 0,
                                       sql_type    => $sqltype,
                                       place       => $param->{fb_position},
                                       publishable => 1,
                                       max_length  => $max,
                                      });

            # create name/value field for element
            $atd->set_attr('html_info', $value);

            # Record the metadata so we can properly display the form element.
            while (my ($k, $v) = each %meta_props) {
                $atd->set_meta('html_info', $k, $param->{$v});
            }

            # Checkboxes need a default value.
            $atd->set_meta('html_info', 'value', 1)
              if $param->{'fb_type'} eq 'checkbox';

            # Log that we've created it.
            log_event("$key\_data_new", $atd, { Name => $key_name });
            log_event("$key\_attr_add", $obj, { Name => $key_name });
        }
    }
};

$save_element_etc = sub {
    my ($self, $obj, $key, $no_save, $disp_name, $name) = @_;
    my $param = $self->params;
    my $cb_key = $self->cb_key;

    # Save the element.
    $obj->save() unless $no_save;
    $param->{"$key\_id"} = $obj->get_id;

    my $containers = $obj->get_containers;
    unless ($no_save) {
        if ($cb_key eq 'save' || $cb_key eq 'save_n_stay') {
            if ($param->{'isNew'}) {
                $self->set_redirect("/admin/profile/$key/" .$param->{"$key\_id"} );
            } else {
                # If this is a top-level element, make sure it as one site and one
                # OC associated with it.
                if ($obj->get_top_level) {
                    my $site_id = $obj->get_sites->[0];
                    unless ($site_id and $obj->get_primary_oc_id($site_id) ) {
                        add_msg("Element must be associated with at least " .
                                "one site and one output channel.");
                        return;
                    }
                }

                # log the event
                my $msg = $key . (defined $param->{"$key\_id"} ? '_save' : '_new');
                log_event($msg, $obj);
                # Record a message and redirect if we're saving.
                add_msg("$disp_name profile \"[_1]\" saved.", $name);
                # return to profile if creating new object
                $self->set_redirect("/admin/manager/$key") unless $cb_key eq 'save_n_stay';
            }
        } elsif ($cb_key eq 'addElement') {
            # redirect, and tack object id onto path
            $self->set_redirect("/admin/manager/$key/" . $param->{"$key\_id"});
        }
    }
};


1;