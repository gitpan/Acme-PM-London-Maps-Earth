use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Acme::PM::London::Maps::Earth',
    'VERSION_FROM'	=> 'Earth.pm',
    'PREREQ_PM'		=> {GD=>1.27, File::Basename=>0.1,strict=>0.1,Data::Dumper=>0.1},

    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'Earth.pm', # retrieve abstract from module
       AUTHOR     => 'Lee Goddard <lgoddard@cpan.org>') : ()),
);
