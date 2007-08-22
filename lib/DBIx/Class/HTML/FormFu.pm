package DBIx::Class::HTML::FormFu;
use strict;
use warnings;
use Carp qw( croak );

our $VERSION = '0.01001';

sub fill_formfu_values {
    my ( $dbic, $form ) = @_;
    
    my $fields;
    eval {
        $fields = $form->get_fields;
    };
    croak "require a compatible form object: $@" if $@;
    
    for my $field (@$fields) {
        my $name = $field->name;
        
        next unless defined $name && $dbic->can( $name );
        
        if ( ref $dbic->$name && $dbic->$name->can('id') && $dbic->$name->id ) {
		    $field->default( $dbic->$name->id );
		}
		else {
            $field->default( $dbic->$name );
		}
    }
    
    return $form;
}

sub populate_from_formfu {
    my ( $dbic, $form ) = @_;
    
    my %checkbox;
    eval {
        %checkbox = 
            map { $_->name => undef }
            grep { defined $_->name }
            @{ $form->get_fields({ type => 'Checkbox' }) || [] };
    };
    croak "require a compatible form object: $@" if $@;
    
    my $params = $form->params;
    
    for my $col ( $dbic->result_source->columns ) {
        my $col_info    = $dbic->column_info($col);
        my $is_nullable = $col_info->{is_nullable} || 0;
        my $data_type   = $col_info->{data_type} || '';
        my $value       = $params->{$col};

        if ( ( $is_nullable
               || $data_type =~ m/^timestamp|date|int|float|numeric/i )
            && defined $value
            && $value eq '')
        {
            $value = undef;
            $dbic->$col($value);
        }
        
        $dbic->$col($value)
            if defined $value || exists $checkbox{$col};
    }

    $dbic->update_or_insert;
    
    return $dbic;
}

1;

__END__

=head1 NAME

DBIx::Class::HTML::FormFu - Fill a HTML::FormFu form from the database and vice-versa

=head1 SYNOPSIS

    # fill a form from the database
    
    my $row = $schema->resultset('Foo')->find($id);
        
    $row->fill_formfu_values( $form )

    # populate the database from a submitted form
    
    if ( $form->submitted && !$form->has_errors ) {
        
        my $row = $schema->resultset('Foo')->find({ id => $params->{id} });
        
        $row->populate_from_formfu( $form );
    }

=head1 SUPPORT

Project Page:

L<http://code.google.com/p/html-formfu/>

Mailing list:

L<http://lists.scsys.co.uk/cgi-bin/mailman/listinfo/html-formfu>

Mailing list archives:

L<http://lists.scsys.co.uk/pipermail/html-formfu/>

=head1 BUGS

Please submit bugs / feature requests to 
L<http://code.google.com/p/html-formfu/issues/list> (preferred) or 
L<http://rt.perl.org>.

=head1 SUBVERSION REPOSITORY

The publicly viewable subversion code repository is at 
L<http://html-formfu.googlecode.com/svn/trunk/DBIx-Class-HTML-FormFu>.

If you wish to contribute, you'll need a GMAIL email address. Then just 
ask on the mailing list for commit access.

If you wish to contribute but for some reason really don't want to sign up 
for a GMAIL account, please post patches to the mailing list (although  
you'll have to wait for someone to commit them). 

If you have commit permissions, use the HTTPS repository url: 
L<https://html-formfu.googlecode.com/svn/trunk/DBIx-Class-HTML-FormFu>

=head1 SEE ALSO

L<HTML::FormFu>, L<DBIx::Class>, L<Catalyst::Controller::HTML::FormFu>

=head1 AUTHOR

Carl Franks

=head1 CONTRIBUTORS

Adam Herzog

Daisuke Maki

Mario Minati

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Carl Franks

Based on the original source code of L<DBIx::Class::HTMLWidget>, copyright 
Thomas Klausner.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut
