package Acme::PM::London::Maps::Earth; # where in the world are London.pm members?

our $VERSION = 0.01;	# See TODO
our $DATE = "Sun Jun 24 14:57:40 2001 BST";

use 5.006;
use strict;
use warnings;
use GD;
use File::Basename;
use Data::Dumper;
use Carp;

=head1 NAME

Acme::PM::London::Maps::Earth - where in the world are London.pm members?

=head1 SYNOPSIS

	use Acme::PM::London::Maps::Earth;

	new Acme::PM::London::Maps::Earth (MAP=>"THE WORLD","PATH"=>"E:/src/pl/out.html");
	# or
	Acme::PM::London::Maps::Earth::all("E:/src/pl/");
	__END__

=head1 DESCRIPTION

Imports a world map, and exports a world map with details of London.pm users scrawled over it, wrapped in an HTML page.  This is a quick hack - no SQL, no CGI, no nice WWW look-ups, nothing.

I was bored and got this message:

	From: london.pm-admin@london.pm.org
	[mailto:london.pm-admin@london.pm.org]On Behalf Of Philip Newton
	Sent: 21 June 2001 11:44
	To: 'london.pm@london.pm.org'
	Subject: Re: headers

	Simon Wistow wrote:
	> It's more a collection of people who have the common connection
	> that they live and london and like perl.
	> In fact neither of those actually have to be true since I personally
	> know two people on the list who don't program Perl and one of whom
	> doesn't even live in London.

	How many off-London people have we got? (Well, also excluding people who
	live near London.)

	From outside the UK, there's Damian, dha, Paul M, I; Lucy and lathos
	probably also qualify as far as I can tell. Marcel used to work in London
	(don't know whether he still does). Anyone else?

	Cheers,
	Philip
	--
	Philip Newton <Philip.Newton@datenrevision.de>
	All opinions are my own, not my employer's.
	If you're not part of the solution, you're part of the precipitate.

In the twenty-second weekly summary of the London Perl Mongers
mailing list, for the week starting 2001-06-18:

	In other news: ... a london.pm world map ...


=head1 PREREQUISITES

	Carp;
	Data::Dumper;
	File::Basename;
	GD;
	strict;
	warnings.


=head1 DISTRIBUTION CONTENTS

	.earth.dat
	london_postcodes.jpg
	uk.jpg
	world.jpg

=head1 TODO

=item * Map all locations to all maps.

=cut

our $chat = 0;

our $CREATIONTXT = "Created on ".(scalar localtime)." by ".__PACKAGE__;

#
# Map file names - shares keys with our %locations.
#
our %MAPS = (
	"THE WORLD" => "world.jpg",
	"THE UK" 	=> "uk.jpg",
	"LONDON"	=> "london_postcodes.jpg",
);


our %locations = ();
{
	local *IN;
	open IN,".earth.dat" or die "Couldn't open the configuration file <.earth.dat> for reading";
	read IN, $_, -s IN;
	close IN;
	my $VAR1; # will come from evaluating the file produced by Data::Dumper.
	eval ($_);
	%locations = %{$VAR1};
}



=head2 Constructor (new)

Returns a new object of this class.  Accepts arguments in a hash, where keys/values are:

=over 4

=item MAP

Either C<THE WORLD>, C<THE UK>, C<LONDON>.

=item PATH

The path at which to save - supply a dummy filename, please, coz I'm lazy.
You will receive a C<.jpg> and C<.html> file in return.

=item CHAT

Set if you want rabbit on the screen.

=back

=cut

sub new { my $class = shift;
	croak"Please call with a package ID" if not defined $class;
	my %args;
	my $self = {};
	bless $self,$class;

	# Take parameters and place in object slots/set as instance variables
	if (ref $_[0] eq 'HASH'){	%args = %{$_[0]} }
	elsif (not ref $_[0]){		%args = @_ }

	# Default instance variables
	$self->{MAP}	= "WORLD";		# Default map cf. our %MAPS
	# Overwrite default instance variables with user's values
	foreach (keys %args) {	$self->{uc $_} = $args{$_} }

	$chat = 1 if exists $self->{CHAT};

	croak "Please supply an output path as parameter PATH\n" if not exists $self->{PATH};
	my ($name,$path,$suffix) = fileparse($self->{PATH},'(\.[^.]*)?$' );
	croak "Please supply a filepath with a dummy extension" if not defined $name;
	$self->{PATH} = $path.$name;

	$self->{IMGPATH} = $path.$name.'.jpg';
	croak "There is no option for a map of $self->{MAP}" if not exists $MAPS{$self->{MAP}};
	croak "No map for $self->{MAP} at " if not -e $MAPS{$self->{MAP}};

	# Try to load the image into our object as a GD object
	open IN, $MAPS{$self->{MAP}} or croak"Could open the $self->{MAP} from $MAPS{$self->{MAP}} ";
	$self->{IM} = GD::Image->newFromJpeg(*IN);
	close IN;

	$self->{HTML} = '';											# Will contain the HTML for the image and image map
	$self->{SPOTCOLOUR} = $self->{IM}->colorAllocate(255,0,0);		# Colour of the spots to be placed on the map
	$self->{SPOTSIZE} = 4; 										# Size of spot on the map in px
	if ($self->{MAP} eq 'THE WORLD') {$self->{SPOTSIZE} = 4}
	elsif ($self->{MAP} eq 'THE UK') {$self->{SPOTSIZE} = 4}
	elsif ($self->{MAP} eq 'LONDON') {$self->{SPOTSIZE} = 12}


	# Now we have the argument for the map in question:
	$self->_add_html_top;
	$self->_add_map_top;
	$self->_populate;
	$self->_add_map_bottom;
	$self->_add_html_bottom;

	$self->_save;
	return 1;
}




#
# Private method _save ($path)
#
# Saves the product of the module.
#
# Accepts a file path at which to save the JPEG and HTML output.
# Supply a filename with any suffix: it will be ignored, and the JPEG image and HTML files will be given C<.jpg> and C<.html>
# suffixes respectively.
#
sub _save { my ($self) = (shift);
	croak "Please call as a method." if not defined $self or not ref $self;
	local (*OUT);

	# Add text to image
	my $title = "London.pm in $self->{MAP}";
	my @textlines = split /(by.*)$/,$CREATIONTXT;
	my ($x,$y) = $self->{IM}->getBounds();
	my @bounds;
	$x = 5;
	$y = 17;
	@bounds = $self->{IM}->stringTTF($self->{SPOTCOLOUR},'Verdanal',10,0,$x,1,$title);
	if ($#bounds==-1){
		warn "Apparently no TTF support for Verdana?\n",@$,"\nTrying simpler method....\n" if $chat;
		#gdGiantFont, gdLargeFont, gdMediumBoldFont, gdSmallFont and gdTinyFont
		$self->{IM}->string(gdMediumBoldFont,$x,1,$title,$self->{SPOTCOLOUR});
		for (0..$#textlines){
			$self->{IM}->string(gdTinyFont,$x,$y+($_*11),$textlines[$_],$self->{SPOTCOLOUR});
		}
	} else {
		for (0..$#textlines){
			@bounds = $self->{IM}->stringTTF($self->{SPOTCOLOUR},'Verdanal',8,0,$x,$y+($_*9),$textlines[$_]);
		}
		warn "Used TTF." if $chat;
	}

	#   the JPEG
	warn "Going to save $self->{PATH}.jpg...\n" if $chat;
	open OUT, ">$self->{PATH}.jpg" or die "Could not save to <$self->{PATH}.jpg> ";
	binmode OUT;
	print OUT $self->{IM}->jpeg;
	close OUT;
	# Save the HTML
	warn "Going to save $self->{PATH}.html...\n" if $chat;
	open OUT, ">$self->{PATH}.html" or die "Could not save to <$self->{PATH}.html> ";
	print OUT $self->{HTML};
	close OUT;
	warn "OK.\n" if $chat;
}



# _populate
#
# Populates the current map.
#
sub _populate { my ($self) = (shift);
	croak "Please call as a method." if not defined $self or not ref $self;
	warn "Populating the $self->{MAP} map.\n" if $chat;
	foreach (@{%locations->{$self->{MAP}}}){
		warn "\tadding @$_\n" if $chat;
		# # foreach (@{%locations->{$self->{MAP}}}){
		$self->_add_to_map(@$_);
	}
}


#
# Private method: _add_to_map
#
# Adds to the current image and to the HTML being created
# 	cf. $self->{IM}, $self->{HTML}.
#
# 	Accepts: x and y co-ordinates in the current map ($self->{MAP})
#			 name of the place on the map
#			 name of the individual placed on the map
#
sub _add_to_map { my ($self, $x,$y,$place,$name) = (@_);
	# Add to the image
	# $self->{IM}->filledRectangle($x-$self->{SPOTSIZE},$y-$self->{SPOTSIZE}, $x+$self->{SPOTSIZE},$y+$self->{SPOTSIZE}, $self->{SPOTCOLOUR} );
	for (0..$self->{SPOTSIZE}){
		$self->{IM}->arc($x,$y,$self->{SPOTSIZE}-$_,$self->{SPOTSIZE}-$_,0,360,$self->{SPOTCOLOUR});
	}

	# Add to the HTML
	$self->{HTML} .= "<area "
		. "shape='circle' coords='$x,$y,$self->{SPOTSIZE}' "
		. "alt='$name in $place' title='$name in $place' "
		. "href='#' target='_self'"
	. ">\n";
}



#
# Private methods: _add_html_top, _add_map_top, _add_map_bottom, _add_html_bottom
#
# Call before adding elements to the map, to initiate up the HTML image map, and include the HTML iamge.
# Optional second argument used as HTML TITLE element contents when no $self->{MAP} has been defined.
#
sub _add_html_top { my $self=shift;
	$self->{HTML} =
	"<html><head><title>";
	if (exists $self->{MAP}){
		$self->{HTML}.="London.pm on the $self->{MAP} map";
	} else {
		$self->{HTML} .= $_[0] if defined $_[0];
	}
	$self->{HTML} .= "</title><meta http-equiv='Content-Type' content='text/html; charset=iso-8859-1'></head>\n<body>\n"
}

sub _add_map_top { my ($self ) = (shift);
	my ($x,$y) = $self->{IM}->getBounds();
	$self->{HTML}
		.="<div align='center'>\n"
		. "<img src='$self->{IMGPATH}' width='$x' height='$y' usemap='#$self->{MAP}' border='1'>\n"
		. "<map name='$self->{MAP}'>\n\n"
	.$self->{HTML};
}

sub _add_map_bottom { my ($self) = (shift);
	$self->{HTML} .= "\n</map>\n</div>\n";
}

sub _add_html_bottom { my ($self) = (shift);
	$self->{HTML} .= "\n</body></html>\n\n";
}

#
# UNUSED Private method: _coords
#
# Maps co-ords from one map to another
#	Accepts: name of map to map onto
#			 x, y co-ords on current map ($self->{MAP})
#	Returns: the new co-ords on the map passed
#
sub _coords { my ($self,$map,$x,$y) = (@_);
	# # foreach (@{%locations->{$self->{MAP}}}){
	if ($self->{MAP} eq $map) {return $x,$y}
	if ($self->{MAP} eq 'WORLD' and $map eq 'UK'){
		warn "self word, looking at UK";
		$x += 315;		# 338
		$y += 98;		# 145
	}
	if ($self->{MAP} eq 'UK' and $map eq 'WORLD'){
	}
	return $x,$y;
}



=head1 &all ($base_path,$base_url)

This subroutine produces all available maps, and an index page.

It accepts two argument, a path at which files can be built, and a corresponding URL. If you supply a filename, it will be ignored.

The following files are produced:

	m_MAPNAME.jpg * number of maps
	m_MAPNAME.html * number of maps
	m_index.html

where MAPNAME is ... the name of the map.

=cut

sub all { my ($file_path) = (shift);
	my ($fname,$fpath,$ext) = fileparse($file_path,'(\.[^.]*)?$' );
	croak "Please supply a base path as requeseted in the POD.\n" if not defined $file_path;
	my $fprefix = 'm_';
	my $self = bless {};
	$self->{HTML} = '';
	$self->_add_html_top("London.pm Maps Index");
	$self->{HTML} .= "<H1>London.pm Maps<HR></H1>\n<UL>";

	foreach my $map (keys %MAPS){
		$map =~ /(\w+)$/;
		die "Error making filename: didn't match regex" if not defined $1;
		$_ = __PACKAGE__;
		my $mapmaker = new (__PACKAGE__,{MAP=>$map, PATH=>$fpath.$fprefix.$1});
		$self->{HTML}.="<LI><A href='$fprefix$1.html'>$1</A></LI>\n";
	}

	$self->{HTML}.="</UL>".
	"These maps were ".(lcfirst $CREATIONTXT).", available on <A href='http://search.cpan.org'>CPAN</A>, from data last updated on $DATE.".
	"<P>Currently the three maps are not cross-mapped, nor postcodes looked up - maybe they will be soon.</P>".
	"<P>Maps originate either from the CIA (who placed them in the public domain), or unknown sources (defunct personal pages on the web).";
	$self->{HTML}.="<BR><HR><P><SMALL>Copyright (C) <A href='mailto:lGoddard\@CPAN.Org'>Lee Goddard</A> 2001 - available under teh same terms as Perl itself</SMALL></P>";

	$self->_add_html_bottom;
	open OUT,">$fpath$fprefix"."index.html" or die "Couldn't open <$fpath$fprefix"."index.html> for writing";
	print OUT $self->{HTML};
	close OUT;
}


=head1 SEE ALSO

perl(1); L<GD>; L<File::Basename>; L<Acme::Pony>; L<Data::Dumper>.

=head1 AUTHOR

Lee Goddard <lgoddard@cpan.org>

=head1 COPYRIGHT

Copyright (C) Lee Goddard, 2001.  All Rights Reserved.

This module is supplied and may be used under the same terms as Perl itself.






=cut

1;

#my $map = new Acme::PM::London::Maps::Earth (MAP=>"THE WORLD","PATH"=>"E:/src/pl/out.html");
&all("E:/src/pl/");
exit;
