#!/usr/bin/perl
# 
# written by: Willians Patiño, 19/01/2011
#
# para migracion masiva de los buzones de correos entre dos servidores Zimbra 
#
#  herramienta complementaria para el proyecto de migracion
#
#  ChangeLogs:
#
#	22/03/2011	- add date+time by each user to process
#				- entry by console to specify users's list filename
#				- generate log in other way
#
#	14/02/2011	- report elapsep time by user
#
#	11/02/2011	- add exclude (Junk)
#			- show elapsed time & date 
#			- enable log on file
#
#	10/02/2011	- change userheader
#
#	09/02/2011	- Ajustar filtro para extraer la cuenta 
#			del usuario desde $RecordLine.
#
#	22.12.2011	- some changes to migrate mailbox from zimbra
#			  to mirror mailserver
#		        - use 'newpass2all' as password file 'cause
#		          all users has the same in order to migrate its
#		          mailbox each one
#	
#	10.2.2012	- insert into code password, required to sync (both)
#			  works with pass instead password file.
#
#	22.2.2012	- save log with timestamp
#			- do not sync Trash in imap folder
#	10.3.2014	- log to /tmp 
#			- passfile instead password as argument
#			- ensure only one instance runs
#			- test mode can be indicated at console
#   19.11.2023  - Argumento por consola: el nombre del archivo con la listas de usuarios


####### DO NOT DELETE #########
use strict;
use warnings;
use Term::ANSIColor;  
use constant false => 0;
use constant true  => 1;
use Fcntl qw(LOCK_EX LOCK_NB);
use File::NFSLock;

# run mode ('true' if you wish no change) 
my $test = true;

# ensure that only one instance runs
my $lock = File::NFSLock->new($0, LOCK_EX|LOCK_NB);
	die "$0 is already running!\n" unless $lock;

 			

&WhatIDo(); my $WhatTask='Migrar mailbox';   # what do this script
my $EntryByUser = false; my $LevelIWant = 0; 
my $Arg1 = ""; my $tst = ''; my $Arg2 = "";

# validate LDAP parameters
&ValidateEntry(); if (!$EntryByUser) {exit;}  # Bye Bye if you wrong!!
if ($Arg2 eq 'notest') 
	{ $test = false;}
else
	{ $test = true;}

# make Log File
my $today = system("date '+%Y%m%d--%H%M%S'"); 

# Log, output will be addressed to /tmp dir as default
my $logfile1 = '/tmp/'.$Arg1.'.imapsynced.log';

open (MYFILE,">$logfile1" );
print MYFILE "Mailbox Synced via imap Log\n";
print MYFILE "======================\n";
print MYFILE "--> Start: ". &timenow()."\n";
print MYFILE "\tRegistros Procesados\n";

# Users list   ::first at all, extracted from LDAP Zimbra


##my $ZimbraUsersList = "ZimbraUsers-sorted.txt"; # Lista de usuarios
my $ZimbraUsersList = $Arg1; # Lista de usuarios
#		---- formato requerido ----
#	  usuario@proviasdes.gob.pe

# IMAP Servers
my $SourceMailServer = "webmail.proviasdes.gob.pe";
my $DestinationMailServer = "mail.proviasdes.gob.ve";

# Mail Command
my $isc = "/usr/bin/imapsync";

my $BufferSize = "8192000";  # Do not change					

my $AdminAccount1 = "admin\@proviasdes.gob.pe";  
my $AdminAccount2 = "admin\@proviasdes.gob.pe";  

my $ZimbraUser = "";

# Parameters
my $buf = "--buffersize $BufferSize";
my $nos = "--nosyncacls";
my $sub = "--subscribe_all"; 
#my $hst1 = "--host1 $SourceMailServer --ssl1";
my $hst1 = "--host1 $SourceMailServer --sslargs1 SSL_verify_mode=1";
my $usr1 = "--user1 $ZimbraUser";

# Auth on host
my $au1 = "--authuser1 $AdminAccount1"; 
my $au2 = "--authuser2 $AdminAccount2"; 

# Auth by file
my $pau1 = "--passfile1 zmigration-fase-final/keys/webmail.txt";
my $pau2 = "--passfile2 zmigration-fase-final/keys/mail.txt";

#my $hst2 = "--host2 $DestinationMailServer --ssl2"; 
my $hst2 = "--host2 $DestinationMailServer --sslargs2 SSL_verify_mode=1"; 
my $usr2 = "--user2 $ZimbraUser";
my $syn = "--syncinternaldates";
my $useh1 = "--useheader 'Message-ID'";
my $useh2 = "--useheader 'Date'";
my $useh3 = "--useheader 'folderName'";
my $ex1 = "--exclude 'Spam'";
my $ex2 = "--exclude 'Trash'";
my $ex3 = "--exclude 'mail-trash'";
my $ex4 = "--exclude 'sent-trash'";
my $ex5 = "--exclude 'spam-trash'";
my $ex6 = "--exclude 'Junk'";
my $ex7 = "--exclude 'Chat'";
my $ex8 = "--exclude 'Emailed\ Contacts'";
#my $log = "| tee -a  $logfile2";
my $countrecord = 0;

# batch proccesing Zimbra's users
open(DATOS,$ZimbraUsersList) || die " no existe el archivo: $ZimbraUsersList\n\n"; 
    while (my $RecordLine = <DATOS>) {
		chomp($RecordLine);
		#my ($FirstParam, $ZimbraUser) = split(/:/, $RecordLine);
		$ZimbraUser = $RecordLine;
		$usr1 = "--user1 $ZimbraUser";
		$usr2 = "--user2 $ZimbraUser";

        $countrecord++;
	
	print "===> "; print color("magenta"),
        "\t\($countrecord\) "."$WhatTask  de  $ZimbraUser ... \n\n";
	print color("reset");

	print MYFILE "\t\($countrecord\)$ZimbraUser (".&timenow().")\n";

	if ($test) { $tst = "--dry --justfoldersizes";}
	else { $tst = '';}

	
	my $Prms = "$buf $nos $sub $hst1 $usr1 $au1 $pau1 $hst2 $usr2 $au2 $pau2 $syn $useh1 $useh2 $useh3 $ex1 $ex2 $ex3 $ex4 $ex5 $ex6 $ex7 $ex8 $tst";
	my $ImapSyncro = $isc.' '.$Prms ;

        
	system("$ImapSyncro" );
   }
close(DATOS);
print MYFILE "====\n";
print MYFILE "--> End: ". &timenow()."\n";
close(MYFILE);

print color("green"),
"check this files:  \n\t- $logfile1 \n\n";
print color("reset");
die "C'est fait \n";

sub WhatIDo {  # What Do thi script
    system("clear");
    print "\n";print color('green'),
    "\tMigrar buzones de correos en base a una lista de cuenta de usuarios\n",
    color('reset');print "\n";
    print color('cyan'),"\t\t * Indique el nombre de la lista \n\n",color('reset');
    
}

sub ValidateEntry { # Check arguments
    my $argm = 1;
    if ($#ARGV != $argm) {  # validate entry
        print color("magenta"),
        "\n\tUso: \n\t\t$0    <lista>  (test|notest)\n",color("reset");
        print "\n"; my $argmt = $argm + 1;
        print color('red'),"\nError de entrada, se requiere $argmt parametro.\n",color('reset');
        print "\n";
        $EntryByUser = false;
    }
    else {
        $Arg1 = $ARGV[0];
        $Arg2 = $ARGV[1];
        $EntryByUser = true;                     
    }
}

sub timenow {
	my @months = qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);
	my @weekDays = qw(Sun Mon Tue Wed Thu Fri Sat Sun);
	my ($second, $minute, $hour, $dayOfMonth, $month, $yearOffset, $dayOfWeek, $dayOfYear, $daylightSavings) = localtime();
	my $year = 1900 + $yearOffset;
	my $theTime = "$hour:$minute:$second, $weekDays[$dayOfWeek] $months[$month] $dayOfMonth, $year";
	#my $theTime = "$year$months[$month]$dayOfMonth.$hour$minute$second";
 return $theTime; 

}
