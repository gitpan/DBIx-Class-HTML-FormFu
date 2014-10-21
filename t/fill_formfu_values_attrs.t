use strict;
use warnings;
use Test::More;

BEGIN {
    if ( !-f 't/test.db' ) {
        plan skip_all => 'To run these tests, '
        . 'run `sqlite3 t/test.db < t/create.sql` to create the test db.';
    }
    
    eval "use DateTime::Format::MySQL";
    if ($@) {
        plan skip_all => 'To run these tests, install DateTime::Format::MySQL';
    }
}

plan tests => 25;

use HTML::FormFu;
use lib 't/lib';
use MySchema;

my $form = HTML::FormFu->new->load_config_file('t/form_attrs.yml');

ok( my $schema = MySchema->connect('dbi:SQLite:dbname=t/test.db') );

my $rs = $schema->resultset('Test');

# make sure db is empty to start
map { $_->delete } grep { defined } $rs->find({});

{
    my $row = $rs->new_result({
        text_col       => 'a',
        password_col   => 'b',
        checkbox_col   => 'foo',
        select_col     => '2',
        radio_col      => 'yes',
        radiogroup_col => '3',
        date_col       => '2006-12-31'
        });
    
    $row->insert;
}

{
    my $row = $rs->find({ hidden_col => 1 });
    
    $row->fill_formfu_values( $form, { prefix_col => 'attrs_' } );
    
    my $fs = $form->get_element;
    
    is( $fs->get_field('attrs_hidden_col')->render->{value}, 1 );
    is( $fs->get_field('attrs_text_col')->render->{value}, 'a');
    is( $fs->get_field('attrs_password_col')->render->{value}, undef);
    
    my $checkbox = $fs->get_field('attrs_checkbox_col')->render;
    
    is( $checkbox->{value}, 'foo' );
    is( $checkbox->{attributes}{checked}, 'checked' );
    
    # accessing undocumented HTML::FormFu internals below
    # may break in the future
    
    my $select = $fs->get_field('attrs_select_col')->render;
    
    is( $select->{options}[0]{value}, 1 );
    ok( !exists $select->{options}[0]{attributes}{selected} );
    
    is( $select->{options}[1]{value}, 2 );
    is( $select->{options}[1]{attributes}{selected}, 'selected' );
    
    is( $select->{options}[2]{value}, 3 );
    ok( !exists $select->{options}[2]{attributes}{selected} );
    
    my @radio = map { $_->render } @{ $form->get_fields('attrs_radio_col') };
    
    is( $radio[0]->{value}, 'yes' );
    is( $radio[0]->{attributes}{checked}, 'checked' );
    
    is( $radio[1]->{value}, 'no' );
    ok( !exists $radio[1]->{attributes}{checked} );
    
    my @rg_option = @{ $fs->get_field('attrs_radiogroup_col')->render->{options} };
    
    is( $rg_option[0]->{value}, 1 );
    ok( !exists $rg_option[0]->{attributes}{checked} );
    
    is( $rg_option[1]->{value}, 2 );
    ok( !exists $rg_option[1]->{attributes}{checked} );
    
    is( $rg_option[2]->{value}, 3 );
    is( $rg_option[2]->{attributes}{checked}, 'checked' );
    
    # column is inflated
    my $date = $fs->get_field('attrs_date_col')->render->{value};
    
    like( $date, qr/31/ );
    like( $date, qr/12/ );
    like( $date, qr/2006/ );
}

# empty db again
map { $_->delete } $rs->find({});
