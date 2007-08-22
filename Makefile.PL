use inc::Module::Install;

name 'DBIx-Class-HTML-FormFu';
all_from 'lib/DBIx/Class/HTML/FormFu.pm';

requires 'DBIx::Class';
requires 'HTML::FormFu';

license 'perl';

auto_install();
&WriteAll;
