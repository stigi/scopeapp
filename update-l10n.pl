#! /usr/bin/perl -w

#  update-l10n.pl
#
#  Script to extract localisable strings in the form _(@"foo") from
#  the source files, used to create English.lproj/Localizable.strings
#
#  Copyright (c) 2002 Philip Derrin
#
#  This file is part of MacCRO X.
#
#  MacCRO X is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 2 of the License, or
#  (at your option) any later version.
#
#  MacCRO X is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with MacCRO X; if not, write to the Free Software
#  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
#
#  $Header: /cvsroot/scopeapp/scopeapp/update-l10n.pl,v 1.1 2002/07/19 07:52:34 narge Exp $
#

opendir SRCDIR,"./src";

@sourcefiles = readdir SRCDIR;

for $file (@sourcefiles)
{
	if($file !~ /\.m$/) { next; }

	print "/** ".$file." **/\n\n";
	
	open SRCFILE,"./src/".$file;
	read SRCFILE, $source, -s SRCFILE;
	while($source =~ /\W_\(\@(.*?)\)/mg)
	{
		if(!$strings{$1})
		{
			print $1." = ".$1.";\n";
		}
		$strings{$1} = 1;
	}
	close SRCFILE;
	print "\n";
}
