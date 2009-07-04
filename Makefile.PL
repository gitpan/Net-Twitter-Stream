

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'Net::Twitter::Stream',
    VERSION_FROM => 'lib/Net/Twitter/Stream.pm', # finds \$VERSION
    AUTHOR       => 'Martin Redmond (@martinredmond)',
    ABSTRACT     => 'Connect to the Twitter streaming api',
    PREREQ_PM    => {
                     'Test::Simple' => 0.44,
		     'Danga::Socket' => 0.0
                    },
);
