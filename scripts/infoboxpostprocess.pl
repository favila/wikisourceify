#!/usr/bin/env perl
use strict;
use Data::Dumper;
use DBI;
use Scalar::Util qw(looks_like_number);
use Locale::Currency::Format;

my $DEBUG = 1;

#I prefer to work with explicit path names to minimize confusion
my $path = `pwd`;
chomp($path);
$path .= '/info/';

my @files;

opendir(DIR, $path);
@files = grep { /\.txt$/ } readdir(DIR);
closedir(DIR);

#loop em
foreach (@files) {
	my @lines = ();
	my $filename = $path."$_";
	open(MYINPUTFILE, "<${filename}"); # open for input
	@lines = <MYINPUTFILE>; # read file into list
	close(MYINPUTFILE);
	$DEBUG and print "Processing $filename\t[";
	$DEBUG and print scalar @lines;
	$DEBUG and print "] lines long\n";

	my @writeme = (); 
	my @moneydetails = (); my @actsdetails = (); my @sectionsdetails = ();
	my %sectionCount = ();
	my $aLine;

	if ($lines[-1] !~ /-30-/) { #skip files we've processed already
		foreach $aLine (@lines) {
#			$aLine =~ s/[, \t]*$//;
			#MONEY                             authorizationsofappropriations
			if (my @lineParts = $aLine =~ /\| (authorizationsofappropriations|appropriations) = (.+),/) {
				$DEBUG and print "$filename: has appropriations and/or authorizations tags.\n";
				my $header = $lineParts[0]; #the line we'll build back up
				push @moneydetails, [$header, ':'];
				my $approps = $lineParts[1];
				my @eachApprop = $approps =~ m/\[.*?\]/g;
				my $totals = 0; my $allnumbers = 1;
				foreach my $oneApprop (@eachApprop) {
					$DEBUG and print "Found $oneApprop\n";
					my($moneystring, $yearstring, $addherup, $itsmoney);
					my($money,$years) = $oneApprop =~ m/\(amount:(.*)\|year:(.*)\)/g;
					#kill the leading and trailing whitespace
					# $money =~ s/^\s+|\s+$//g;
					# $years =~ s/^\s+|\s+$//g;
					#KILL ALL WHITESPACE
					$money =~ tr/ //ds;
					$years =~ tr/ //ds;
					$DEBUG and print "\tso money:$money, years:$years\n";
									
					#my @appropParts = $oneApprop =~ m/\(amount:(.*)\|year:(.*)\)/g;
					if (looks_like_number($money)) {
#						print "$money, ";
						$addherup = $money;
						$itsmoney = 1;
						$DEBUG and print "\t\tthem's real dollars\n";
					} else {
#						print "we got a non numeric in here!\n";
						$itsmoney = $allnumbers = 0;
						$moneystring = "$money";
						$DEBUG and print "\t\tnot numeric\n";
						#push @moneydetails, "$money over years: $years";
					}
					#push @moneydetails, "$money over years: $years";
					#now let's figure out the year syntax
					#wow I look like a first year... don't judge me - I had a matching brace issue!
					if ($years =~ m/^(\d+)$/) { # when y:
#						print "only a year: $years\n";
						#match the year, output "in fiscal [year]”
						#in this case we just did it in the find since it's pretty simple; it's in $1
						$yearstring = "in fiscal year $1.";
						#we don't need to alter $addherup since we're doing one year only
						$DEBUG and print "\t\tyear is in y: format\n";
					}
					else {
						if ($years =~ m/^[\d,]+$/) { #when y,y,y,y:
#							print "years and commas : $years\n";
							#match multiple years - every number cluster (which is nice and easy since it's comma sep)
							my (@allyears) = $years =~ m/(\d+)/g;
							$yearstring = "for each of fiscal years " . join(', ', @allyears);
							#find the last , YYYY and replace it with and
							$yearstring =~ s/, (\d+)$/ and $1/;
							#we need to multiply the $addherup by how many years are listed here
							$addherup *= scalar @allyears;
							$DEBUG and print "\t\tyear is in y,y,y,y format\n";
						}
						else {
							if ($years =~ m/(\d+)\.\.(\d+)/) {# when y..y:
#								print "year..year : $years\n";
								#also simple, matched on $1 $2
								#over fiscal [firstyear] through [lastyear]”
								$yearstring = "over fiscal $1 through $2";
								$addherup *= ($2 - $1);
								$DEBUG and print "\t\tyear is in y..y format\n";
							} else {
								if ($years =~ m/(\d+),\.\./) {# when y,..: # when y..:
#									print "year,.. : $years\n";
									#matched on $1
									$yearstring = "in fiscal $1 and each succeeding fiscal year";
									$addherup *= 20;
									$DEBUG and print "\t\tyear is in y,.. format\n";
								} else {
									if ($years =~ m/(\d+)\.\./) {#when y..:
#										print "year.. : $years\n";
										#matched on $1
										$yearstring = "in fiscal $1, to be spent at any time";
										#we're using 
										$addherup *= 20;
										$DEBUG and print "\t\tyear is in y.. format\n";
									} else { #must be blank
#										print "blank/indef : $years\n";
										$yearstring = "";
									}
								}
							}
						}
					}
					#add up the totals
					if ($itsmoney) {
						$totals = $totals + $addherup;
						$moneystring = currency_format('usd',$addherup,FMT_SYMBOL|FMT_NOZEROS);#. " over years: $years";
					}
					push @moneydetails, [$moneystring,$yearstring];

				} #end looping the approp(s)
				$DEBUG and print "\t\tall told that constructs up to:\n".Dumper(@moneydetails)."\n";

				#at this point we can check to see if our yearstrings are all identical
				#if so we're going to shitcan them all and we'll just be using the total
				#if they are consistent then we can present the total with just this one yearstring
				#NOTE: we must skip position [0] since we're using it to identify approp type
				my @processarray = @moneydetails;
				shift @processarray;
				my $lastvalue = shift @processarray;
				my $mismatchedyears = 0;
  				foreach my $nextvalue (@processarray) {
  					if (@$lastvalue[1] ne @$nextvalue[1]) {
#						print "MISMATCH\n";
#						print "\t@$lastvalue[1]\n\t@$nextvalue[1]\n";
						$mismatchedyears = 1;
					}
					$lastvalue = $nextvalue;
				}

				my $newline;

				# For our finances results we have three possibilities:
				# 1: All numeric - there are no indefinite appropriations; say so.
				# 2: Only indefinite - there are no fixed dollar amounts; say so.
				# 3: Both - there are indefinite appropriations as well as some fixed ones. Indicate + include definite amount

				if ($allnumbers) {
					#push @writeme, 
					$newline = "| $header = ".currency_format('usd',$totals,FMT_SYMBOL|FMT_NOZEROS);				
					$DEBUG and print "\t\tall told that constructs up to:\n".Dumper(@moneydetails)."\n";
				} elsif ($totals > 0) {
					$newline = "| $header = At least ". currency_format('usd',$totals,FMT_SYMBOL|FMT_NOZEROS) ." with an additional unlimited amount";					
				} else {
					$newline = "| $header = an unlimited amount";
				}

				#tack on the appropriate year ender
				if ($mismatchedyears) {
					$newline = $newline . "\n";
				} else {
					$newline = $newline . " @$lastvalue[1]\n";
				}
				push @writeme, $newline;
			#end appropriations section
			#ACTS
			} elsif (my @lineParts = $aLine =~ /\| (acts affected)\ += (\".*)/) {
#				$DEBUG and print "$filename: has impacted acts.\n";
				my $header = $lineParts[0]; #the line we'll build back up
				#push @actsdetails, $header. ':';
				my $acts = $lineParts[1];
				my @eachActs = $acts =~ m/\"[^\[]+ \[\d+\]\"/g;
				my %actHash;
				foreach my $oneAct (@eachActs) {
					my($actName,$actOccurrences) = $oneAct =~ m/\"([^\]]+) \[(\d+)\]\"/g;
					$actHash{$actName} = $actOccurrences;
				}
				my @sortedActs = map { { ($_ => $actHash{$_}) } } sort {$actHash{$b} <=> $actHash{$a}} keys %actHash;
				#at this point 
				my @tmpActs = ();
				my $newline = "| $header = "; my $counter = 0;
				foreach my $hashref (@sortedActs) {
				    my($key, $value) = each %$hashref;
				    push @actsdetails, "\t$value:\t$key\n";
				    if ($counter++ < 5) { $newline .= "[[$key]], ";}
				    #else { $newline .= "\"$key\", ";}
				    #print "$key => $value\n";
				}
				if ($counter > 4) { #indicate we truncated the list
					$newline .= "and others.";
				}
				push @writeme, "$newline\n";

			} elsif (my @lineParts = $aLine =~ /\| (sections affected) = (.*)$/) { #sections affected
#				$DEBUG and print "$filename: has impacted sections.\n";
				my $header = $lineParts[0]; #the line we'll build back up
#				$DEBUG and print "\t$aLine\n";
				my $newline = "| $header = ";# my $counter = 0;
				my $sections = $lineParts[1];
				#TODO: Look out for this - we now need to cope with USC and Usc-title-chap
				# SO BE SURE THIS IS STILL WORKING
				my @eachSections = $sections =~ m/{{(?:USC|Usc-title-chap)\|[^}]*}}[^{]*/g;
				foreach my $oneSection (@eachSections) {
					#we could remove this in the initial xsl but better to keep a readable output pre-processing
					$oneSection =~ s/[, ]+$//;
#					$DEBUG and print Dumper $oneSection;					
					# my @sectionBits = split(/\|/, $oneSection);
					# $DEBUG and print Dumper @sectionBits;
					# check to see if we have an entry in %sectionCount for $oneSection
					# if so, +1
					# if not, = 1
					if (exists $sectionCount{$oneSection})	{
						$sectionCount{$oneSection} += 1;
					} else {
						$sectionCount{$oneSection} = 1;
					}
				}
				#DEBUG
#				$DEBUG and print Dumper %sectionCount;
				# given this hash of section reference counts we need to sort them and only output the top 5 at this point

				my @sortedSections = map { { ($_ => $sectionCount{$_}) } } sort {$sectionCount{$b} <=> $sectionCount{$a}} keys %sectionCount;
				#at this point 
#				$DEBUG and print Dumper @sortedSections;
				my $newline = "| $header = "; my $counter = 0;
				foreach my $hashref (@sortedSections) {
				    my($key, $value) = each %$hashref;
				    push @sectionsdetails, "\t$value:\t$key\n";
				    if ($counter++ < 5) { $newline .= "$key, ";}
				    #else { $newline .= "\"$key\", ";}
				    #print "$key => $value\n";
				}
				if ($counter > 4) { #indicate we truncated the list
					$newline .= "and others.";
				}
				push @writeme, "$newline\n";			
			} else { #for the moment non-approp lines pass through unaltered
				push @writeme, $aLine;
			}
		} #end foreach line

		#open the file
		open(INFOBOX, ">${filename}")  || die $!;	
		#write out the fields
		foreach (@writeme) {
			$_ =~ s/[, \t]*$//;			
			print INFOBOX $_;
		}
		print INFOBOX "++++++++++++++++++++++++++++++\n\n\n";

		foreach my $aMoney (@moneydetails) {
			print INFOBOX @$aMoney[0] . ' ' . @$aMoney[1] . "\n";
		}	
		#add any supplimental information. auto-grab from govtrack?	

		print INFOBOX "\n\nActs impacted, by reference count:\n";
		foreach my $anAct (@actsdetails) {
			print INFOBOX "$anAct";
		}	

		print INFOBOX "\n\nSections impacted, by reference count:\n";
		foreach my $aSection (@sectionsdetails) {
			print INFOBOX "$aSection";
		}	

		print INFOBOX "\n-30-";
		close INFOBOX;

	} #unprocessed files
	else {
		$DEBUG and print "Skipping $filename\n";
	}
} #each file