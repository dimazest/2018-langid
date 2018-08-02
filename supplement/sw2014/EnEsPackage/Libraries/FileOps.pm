package FileOps;

# Elizabeth Blair
# Last Edited: 10/04/13

use strict;
use warnings;
use v5.10;

# For files with particular encoding: append '::'+encoding type to end of file name
# Note: file names and locations cannot contain '::'

# Uses same file name in each location given for directories
# You're only getting one output file per output location you gave, not more
# Could re-enter the directory with a different file extension
#	(extension must include period, but can have things before period because of that)
sub runDir
{
	my ($inputRef,$outputRef,$sub,$basedir,$extRef) = @_;
	my @inputs = @{$inputRef};
	my @outputs = @{$outputRef};
	my @exts = @{$extRef};	# Contains extensions for ALL LOCATIONS INVOLVED (in and out)

	chdir($basedir) or die "Couldn't return to $basedir";

	my $fileSource;	# Location to get all of the repeated file names from and its index
	my $sourceNum = 0;
	foreach(@inputs)
	{
		if (-d $_)	{ $fileSource = $_; last; }
		else		{ $sourceNum++; }
	}

	# Gather file names to use from input directory - Only gather files of first file extension
	opendir(my $inDir,$fileSource) or die "Couldn't open directory $fileSource";
	say "Searching in directory $fileSource";
	my @fnames;
	foreach my $entry (readdir($inDir))
	{
		chdir($basedir) or die "Couldn't return to $basedir";
		chdir($inDir) or die "Couldn't change directory to $fileSource";
		if ($entry =~ /^\.|^~/) { next; }	# Skip hidden and temp files
		if (-d $entry)
		{	# Recursive step: Tack this dir onto all other dirs in in and out, recurse
			# All directories MUST have the same internal subdir structure
			my @newInputs = map { -d "$basedir/$_" ? "$_/$entry" : $_ } @inputs;
			my @newOutputs = map { -d "$basedir/$_" ? "$_/$entry" : $_ } @outputs;

			runDir(\@newInputs,\@newOutputs,$sub,$basedir,\@exts);
			next;
		}
		my $extNoEnc = $exts[$sourceNum];
		$extNoEnc =~ s/::.+$//;
		if ($entry =~ /$extNoEnc$/) { push(@fnames,$entry); }
	}
	closedir($inDir) or die "Couldn't close directory $fileSource";
	chdir($basedir) or die "Couldn't return to $basedir";

	foreach(@fnames)
	{
		my $rawName = $_;
		$rawName =~ s/\.[^\.]+$//;
		my @inFiles;
		for(my $i = 0; $i < scalar(@inputs); $i++)
		{
			if (-f $inputs[$i])
			{
				my $temp;
				if ($inputs[$i] =~ /::(.+)$/)
				{
					$inputs[$i] =~ s/::(.+)$//;
					open($temp,"<:encoding($1)",$inputs[$i]) or die "Couldn't open file $inputs[$i] for input";
				}
				else	{ open($temp,'<',$inputs[$i]) or die "Couldn't open file $inputs[$i] for input"; }
				push(@inFiles,$temp);
				next;
			}

			my $tempName = $rawName."$exts[$i]";

			my $tempFile;
			if ($tempName =~ /::(.+)$/)
			{
                $tempName =~ s/::(.+)$//;
				open($tempFile,"<:encoding($1)","$inputs[$i]/$tempName") or die "Couldn't open file $tempName in $inputs[$i] for input";
			}
			else	{ open($tempFile,'<',"$inputs[$i]/$tempName") or die "Couldn't open file $tempName in $inputs[$i] for input"; }

			push(@inFiles,$tempFile);
		}
		my @outFiles;
		for(my $i = 0; $i < scalar(@outputs); $i++)
		{
			if (-f $outputs[$i])
			{
				my $temp;
				if ($outputs[$i] =~ /::(.+)$/)
				{
					$outputs[$i] =~ s/::(.+)$//;
					open($temp,">:encoding($1)",$outputs[$i]) or die "Couldn't open file $outputs[$i] for output";
				}
				else	{ open($temp,'>',$outputs[$i]) or die "Couldn't open file $outputs[$i] for output"; }
				push(@outFiles,$temp);
				next;
			}

			my $tempName = $rawName."$exts[scalar(@inputs)+$i]";

			my $tempFile;
			if ($tempName =~ /::(.+)$/)
			{
				$tempName =~ s/::(.+)$//;
				open($tempFile,">:encoding($1)","$outputs[$i]/$tempName") or die "Couldn't open file $tempName in $outputs[$i] for output";
			}
			else	{ open($tempFile,'>',"$outputs[$i]/$tempName") or die "Couldn't open file $tempName in $outputs[$i] for output"; }

			push(@outFiles,$tempFile);
		}

		say "Running on file $rawName";
		&$sub(@inFiles,@outFiles);

		foreach(@inFiles) { close($_) or die "Couldn't close input file"; }
		foreach(@outFiles) { close($_) or die "Couldn't close output file"; }
	}
}

# Run one instance of the subroutine with given inputs and outputs in respective references
sub runFile
{
	my ($inputRef,$outputRef,$sub,$extRef) = (shift,shift,shift,shift);
	my @inputs = @{$inputRef};
	my @outputs = @{$outputRef};
    my @exts = @{$extRef};
    my $count = 0;
    
	my @infiles;
	foreach(@inputs)
	{
		my $temp;
        $_ =~ s/\.[^\.]+$//;
        my $tempName = $_."$exts[$count]";
        
		if ($tempName =~ /::(.+)$/)
		{
			$tempName =~ s/::(.+)$//;
			open($temp,"<:encoding($1)",$tempName) or die "Couldn't open file $_ for input";
		}
		else	{ open($temp,'<',$tempName) or die "Couldn't open file $_ for input"; }
		push(@infiles,$temp);
        $count++;
	}
	my @outfiles;
	foreach(@outputs) 
	{
		my $temp;
        $_ =~ s/\.[^\.]+$//;
        my $tempName = $_."$exts[$count]";
        
		if ($tempName =~ /::(.+)$/)
		{
			$tempName =~ s/::(.+)$//;
			open($temp,">:encoding($1)",$tempName) or die "Couldn't open file $_ for output";
		}
		else	{ open($temp,'>',$tempName) or die "Couldn't open file $_ for output"; }
		push(@outfiles,$temp);
        $count++;
	}

	my $inprint = join(', ', map { /([^\/]+)$/; $1; } @inputs);
	my $outprint = join(', ',map { /([^\/]+)$/; $1; } @outputs);
	say "Running $inprint to $outprint";
	&$sub(@infiles,@outfiles);

	foreach(@infiles) { close($_) or die "Couldn't close input file"; }
	foreach(@outfiles) { close($_) or die "Couldn't close output file"; }
}

# Either take in input and output array references (of file locations) or make them from
# the given file locations, then pick either one file or full dir depending on input type
# Can take empty reference as either inputs or outputs
sub runFiles
{
	my ($input,$output,$sub) = (shift,shift,shift);
	my ($inputRef,$outputRef);
    my ($basedir,$ext) = (shift,shift);

	if (ref $input eq 'ARRAY') { $inputRef = $input; }
	else { $inputRef = [$input]; }
#	elsif (-f $input or -d $input) { $inputRef = [$input]; }
#	else { die "Input is neither array reference nor single file/dir"; }

	if (ref $output eq 'ARRAY')	{ $outputRef = $output; }
	else 				{ $outputRef = [$output]; }

	# If any input file location is a directory, use runDir
	foreach(@{$inputRef})
	{
		if (-d $_)
		{
			unless (ref $ext eq 'ARRAY') { $ext = [$ext]; }
			runDir($inputRef,$outputRef,$sub,$basedir,$ext);
			goto END;
		}
	}
	# Only use runFile if no input was a directory
	runFile($inputRef,$outputRef,$sub,$ext);

END:	print "\n";
}


# -------------------------------------------------------------------------------------


sub runDirAppend
{
	my ($inDir,$out,$sub,$basedir) = @_;
	chdir($basedir) or die "Couldn't return to $basedir";
	opendir(my $in, $inDir) or die "Couldn't open directory $inDir";

	# Gather file names to use from input directory
	foreach(sort(readdir($in)))
	{
		chdir($basedir) or die "Couldn't return to $basedir";
		chdir($inDir) or die "Couldn't change directory to $inDir";
		if ($_ =~ /^\.|^~/) { next; }	# Skip hidden and temp files
		if (-d $_) { runDirAppend("$inDir/$_",$out,$sub,$basedir); next; }
		open(my $inFile,'<',$_) or die "Couldn't open file $_ in $inDir for input";
		say "Running $_ in $inDir";
		&$sub($inFile,$out);
		close($inFile) or die "Couldn't close input file $_";
	}
	closedir($in) or die "Couldn't close directory $inDir";
	chdir($basedir) or die "Couldn't return to $basedir";
}

# INPUT
# For one file: input file loc, output file loc, ref to subroutine to run on files
# For full directory: input dir loc, output file loc, ref to sub for files, original base dir
sub runFilesAppend
{
	my ($input,$output,$sub) = (shift,shift,shift);
	if (-f $input)
	{
		say "Running $input to $output";
		open(my $in,'<',$input) or die "Couldn't open file $input for input";
		open(my $out,'>>',$output) or die "Couldn't open file $output for output";
		&$sub($in,$out);
		close($in) or die "Couldn't close file $input";
		close($out) or die "Couldn't close file $output";
		print "\n";
	}
	elsif (-d $input)
	{	
		my $basedir = shift;
		open(my $outFile,'>>',$output) or die "Couldn't open file $output for output";
		runDirAppend($input,$outFile,$sub,$basedir);
		close($outFile) or die "Couldn't close output file $output";
		print "\n";
	}
	else	{ die "Invalid input - arguments should be either files or directory and file"; }
}

1;
