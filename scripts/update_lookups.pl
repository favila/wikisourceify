#!/usr/bin/env perl
use strict;
#use warnings;
use LWP::Simple;
use Text::CSV;
use IO::Lines;
# use XML::Smart;
use XML::Writer;
use open ':encoding(utf8)';
use File::Slurp;
# use Cwd;
# use lib cwd();
use Data::Dumper;

my $DEBUG = 1;

#URLs are explicit about sheet on only so we can use additional ones for info, calc, whaever
my $federal_agencies_url = "https://docs.google.com/spreadsheet/pub?key=0Asq4MpW95tWqdEFfeFRmUC1UYjI2S190RDRmRDYzVnc&single=true&gid=0&output=csv";
my $committees_url = "https://docs.google.com/spreadsheet/pub?key=0Asq4MpW95tWqdE8zU3NBZGpRbXZJdHlnRGlOUzZ6NEE&single=true&gid=0&output=csv";
my $people_url = "https://docs.google.com/spreadsheet/pub?key=0Asq4MpW95tWqdDJwUEExb0E0QURlSzNxUlIyUWVGeHc&single=true&gid=0&output=csv";
my $public_law_url = "https://docs.google.com/spreadsheet/pub?key=0Asq4MpW95tWqdGpnMktNdzBYbDBuMGR0eXpqTU5ZREE&single=true&gid=0&output=csv";

my $fa_content = get $federal_agencies_url;
my @fa_lines = split(/\n/, $fa_content);
$DEBUG and print "\nFederal agencies downloaded.\n\tLines: ".scalar @fa_lines;

my $c_content = get $committees_url;
my @c_lines = split(/\n/, $c_content);
$DEBUG and print "\nCommittees downloaded.\n\tLines: ".scalar @c_lines;

my $p_content = get $people_url;
my @p_lines = split(/\n/, $p_content);
$DEBUG and print "\nPeople downloaded.\n\tLines: ".scalar @p_lines;

my $pl_content = get $public_law_url;
my @pl_lines = split(/\n/, $pl_content);
$DEBUG and print "\nPublic laws downloaded.\n\tLines: ".scalar @pl_lines;

my $federal_agencies = new IO::Lines \@fa_lines;
my $fa_csv = Text::CSV->new();
$fa_csv->column_names($fa_csv->getline($federal_agencies)); # use header
my $server_fa_doc = "";
my $serverfaXML = XML::Writer->new(OUTPUT=>\$server_fa_doc, DATA_MODE=>1, DATA_INDENT=>'  ');
my $client_fa_doc = "";
my $clientfaXML = XML::Writer->new(OUTPUT=>\$client_fa_doc, DATA_MODE=>1, DATA_INDENT=>'  ');

my $committees = new IO::Lines \@c_lines;
my $c_csv = Text::CSV->new();
$c_csv->column_names($c_csv->getline($committees)); # use header
my $server_c_doc = "";
my $servercXML = XML::Writer->new(OUTPUT=>\$server_c_doc, DATA_MODE=>1, DATA_INDENT=>'  ');
my $client_c_doc = "";
my $clientcXML = XML::Writer->new(OUTPUT=>\$client_c_doc, DATA_MODE=>1, DATA_INDENT=>'  ');

my $people = new IO::Lines \@p_lines;
my $p_csv = Text::CSV->new();
$p_csv->column_names($p_csv->getline($people)); # use header
my $server_p_doc = "";
my $serverpXML = XML::Writer->new(OUTPUT=>\$server_p_doc, DATA_MODE=>1, DATA_INDENT=>'  ');
my $client_p_doc = "";
my $clientpXML = XML::Writer->new(OUTPUT=>\$client_p_doc, DATA_MODE=>1, DATA_INDENT=>'  ');

my $public_laws = new IO::Lines \@pl_lines;
my $pl_csv = Text::CSV->new();
$pl_csv->column_names($p_csv->getline($public_laws)); # use header
my $server_pl_doc = "";
my $serverplXML = XML::Writer->new(OUTPUT=>\$server_pl_doc, DATA_MODE=>1, DATA_INDENT=>'  ');
my $client_pl_doc = "";
my $clientplXML = XML::Writer->new(OUTPUT=>\$client_pl_doc, DATA_MODE=>1, DATA_INDENT=>'  ');

#Public laws
$clientplXML->startTag("items");
$serverplXML->startTag("entities");
$DEBUG and print "\nProcessing public laws: ";
while ( my $pl_row = $pl_csv->getline_hr( $public_laws ) ) {
	$DEBUG and print ".";
	#build the xml
	#in the csv:
		#columns: ID	ParentID	Abbr	OfficialName	HistoricalName	LeadershipName	Wikipedia
	#for the local wikipedia:
		#<item id="9554" name="Interagency Council on the Homeless" wikipedia="United States Interagency Council on Homelessness" />
	$clientplXML->emptyTag("item", 
			id=>$pl_row->{'ID'}, 
			name=>$pl_row->{'Name'},
			wikipedia=>$pl_row->{'Wikipedia'}
		);
	# for the server:
	#   <entitites>
	#	<entity id="0500" parent-id="0000"><name role="official">Government Accountability Office</name>
	#     		<name role="historical">General Accounting Office</name><name role="leadership">Comptroller General of the United States</name>
	#     		<abbr>GAO</abbr>
	# 	</entity>
	$serverplXML->startTag("entity", id=>$pl_row->{'Name'});
	$serverplXML->dataElement("name", $pl_row->{'Name'});
	$serverplXML->endTag("entity");
}
$clientplXML->endTag("items");
$clientplXML->end();
$serverplXML->endTag("entities");
$serverplXML->end();

#FEDERAL AGENCIES!
$clientfaXML->startTag("items");
$serverfaXML->startTag("entities");
$DEBUG and print "\nProcessing federal agencies: ";
while ( my $fa_row = $fa_csv->getline_hr( $federal_agencies ) ) {
	$DEBUG and print ".";
	#build the xml
	#in the csv:
		#columns: ID	ParentID	Abbr	OfficialName	HistoricalName	LeadershipName	Wikipedia
	#for the local wikipedia:
		#<item id="9554" name="Interagency Council on the Homeless" wikipedia="United States Interagency Council on Homelessness" />
	$clientfaXML->emptyTag("item", 
			id=>$fa_row->{'ID'}, 
			parentid=>$fa_row->{'ParentID'}, 
			name=>$fa_row->{'OfficialName'},
			wikipedia=>$fa_row->{'Wikipedia'}
		);
	# for the server:
	#   <entitites>
	#	<entity id="0500" parent-id="0000"><name role="official">Government Accountability Office</name>
	#     		<name role="historical">General Accounting Office</name><name role="leadership">Comptroller General of the United States</name>
	#     		<abbr>GAO</abbr>
	# 	</entity>
	$serverfaXML->startTag("entity", 
			id=>$fa_row->{'ID'}, 
			parentid=>$fa_row->{'ParentID'} );
	$serverfaXML->dataElement("name", $fa_row->{'OfficialName'}, role => 'official') if $fa_row->{'OfficialName'};
	$serverfaXML->dataElement("name", $fa_row->{'HistoricalName'}, role => 'historical') if $fa_row->{'HistoricalName'};
	$serverfaXML->dataElement("name", $fa_row->{'LeadershipName'}, role => 'leadership') if $fa_row->{'LeadershipName'};
	$serverfaXML->dataElement("abbr", $fa_row->{'Abbr'}) if $fa_row->{'Abbr'};
	$serverfaXML->dataElement("wikipedia", $fa_row->{'Wikipedia'}) if $fa_row->{'Wikipedia'};
	$serverfaXML->endTag("entity");
}
$clientfaXML->endTag("items");
$clientfaXML->end();
$serverfaXML->endTag("entities");
$serverfaXML->end();

#COMMITTEES!
$clientcXML->startTag("items");
$servercXML->startTag("entities");
$DEBUG and print "\nProcessing committees: ";
while ( my $c_row = $c_csv->getline_hr( $committees ) ) {
	$DEBUG and print ".";
	#in the csv:
	#committees
	#columns ID	ParentID	OfficialName	OtherName	Wikipedia
	#for the local wikipedia:
	#<items><item id="JCSE00" name="Commission on Security and Cooperation in Europe" wikipedia="Commission on Security and Cooperation in Europe" />
	$clientcXML->emptyTag("item", 
			id=>$c_row->{'ID'},
			name=>$c_row->{'OfficialName'},
			wikipedia=>$c_row->{'Wikipedia'}
		);	
	#for the server
	  # <entity id="SPAG00">
	  #   <name role="official">Senate Select Committee on Aging</name>
	  #   <name>Senate Special Committee on Aging</name>
	  #   <name>Special Committee on Aging of the Senate</name>
	  # </entity>
	if ($c_row->{'ParentID'} ) {
		$servercXML->startTag("entity", 
				id=>$c_row->{'ID'}, 
				parentid=>$c_row->{'ParentID'} );
	} else {
		$servercXML->startTag("entity", 
				id=>$c_row->{'ID'});		
	}
	$servercXML->dataElement("name", $c_row->{'OfficialName'}, role => 'official') if $c_row->{'OfficialName'};
	$servercXML->dataElement("name", $c_row->{'OtherName'}) if $c_row->{'OtherName'};
	$servercXML->dataElement("name", $c_row->{'OtherName2'}) if $c_row->{'OtherName2'};
	$servercXML->dataElement("wikipedia", $c_row->{'Wikipedia'}) if $c_row->{'Wikipedia'};
	$servercXML->endTag("entity");	  
}
$clientcXML->endTag("items");
$clientcXML->end();
$servercXML->endTag("entities");
$servercXML->end();

#PEOPLE!
$clientpXML->startTag("items");
$serverpXML->startTag("entities");
$DEBUG and print "\nProcessing people: ";
while ( my $p_row = $p_csv->getline_hr( $people ) ) {
	$DEBUG and print ".";
	#build the xml
	#in the csv:
	#people
	#columns ID	GovtrackID	LISID	Title	State	District	LastName	FirstName	NameAndIdentifier	Wikipedia
	#for the local wikipedia:
	#<items><item id="B001265" name="Sen. Mark Begich (D, AK)" wikipedia="Mark_Begich" lis_id="S319" />
	if ($p_row->{'LISID'}) {
		$clientpXML->emptyTag("item", 
			id=>$p_row->{'ID'},
			lis_id=>$p_row->{'LISID'},
			name=>$p_row->{'NameAndIdentifier'},
			wikipedia=>$p_row->{'Wikipedia'}
		);		
	} else {
		$clientpXML->emptyTag("item", 
				id=>$p_row->{'ID'},
				name=>$p_row->{'NameAndIdentifier'},
				wikipedia=>$p_row->{'Wikipedia'}
			);				
	}
	# push(@{$client_pXML->{'items'}{'item'}}, {id=>$p_row->{'ID'}, name=>$p_row->{'NameAndIdentifier'}, wikipedia=>$p_row->{'Wikipedia'}, lis_id=>$p_row->{'LISID'}});
	#for the server
	  # <entity id="B001230" govtrackid="400013" title="Sen." state="WI">
	  #   <name lastname="Baldwin" firstname="Tammy">Sen. Tammy Baldwin (D, WI)</name>
	  # </entity>
	if ($p_row->{'LISID'} ) {
		$serverpXML->startTag("entity", 
				id=>$p_row->{'ID'}, 
				govtrackid=>$p_row->{'GovtrackID'},
				title=> $p_row->{'Title'},
				state=> $p_row->{'State'} );
	} else {
		$serverpXML->startTag("entity", 
				id=>$p_row->{'ID'}, 
				govtrackid=>$p_row->{'GovtrackID'},
				title=> $p_row->{'Title'},
				state=> $p_row->{'State'},
				lis_id=>$p_row->{'LISID'} );
	}
	$serverpXML->dataElement("name", $p_row->{'NameAndIdentifier'}, lastname => $p_row->{'LastName'}, firstname => $p_row->{'FirstName'});
	$serverpXML->dataElement("wikipedia", $p_row->{'Wikipedia'}) if $p_row->{'Wikipedia'};
	$serverpXML->endTag("entity");	 	  
}
$clientpXML->endTag("items");
$clientpXML->end();
$serverpXML->endTag("entities");
$serverpXML->end();

#write out 
	# $client_fa_doc to federal-body.xml
    write_file('lookups/federal-body.xml', {binmode => ':utf8'}, $client_fa_doc);
	$DEBUG and print "\nWriting federal bodies, client file";
	# $client_c_doc to committee.xml
    write_file('lookups/committee.xml', {binmode => ':utf8'}, $client_c_doc);
	$DEBUG and print "\nWriting committees, client file";
	# $client_p_doc to person.xml
    write_file('lookups/person.xml', {binmode => ':utf8'}, $client_p_doc);
	$DEBUG and print "\nWriting people, client file";
	# client_pl_doc to public_law.xml
    write_file('lookups/public_law.xml', {binmode => ':utf8'}, $client_pl_doc);
	$DEBUG and print "\nWriting public laws, client file";

#write out 
	# $server_fa_doc to federal-bodies.xml
	# $server_c_doc to committees.xml
	# $server_p_doc to people.xml
	# server_pl_doc to acts.xml
