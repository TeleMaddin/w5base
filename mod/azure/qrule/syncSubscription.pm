package azure::qrule::syncSubscription;
#######################################################################
=pod

=encoding latin1

=head3 PURPOSE

This QualityRule compares a W5Base/Darwin CloudArea to AZURE Subscription.

=head3 IMPORTS


=head3 HINTS

[en:]


[de:]



=cut

#######################################################################
#
#  W5Base Framework
#  Copyright (C) 2021  Hartmut Vogler (it@guru.de)
#
#  This program is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 2 of the License, or
#  (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program; if not, write to the Free Software
#  Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
#
use strict;
use vars qw(@ISA);
use kernel;
use kernel::QRule;
@ISA=qw(kernel::QRule);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);

   return($self);
}

sub getPosibleTargets
{
   return(["itil::itcloudarea"]);
}

sub qcheckRecord
{
   my $self=shift;
   my $dataobj=shift;
   my $rec=shift;
   my $checksession=shift;
   my $autocorrect=shift;

   my $wfrequest={};
   my $forcedupd={};
   my @qmsg;
   my @dataissue;
   my $errorlevel=0;


   return(undef,undef) if ($rec->{cloud} ne "AZURE" &&
                           $rec->{cloud} ne "Azure_DTIT");
   return(undef,undef) if ($rec->{cistatusid}<3);

   my $app=getModuleObject($self->getParent->Config(),"itil::appl");
   $app->SetFilter({id=>\$rec->{applid}});
   my ($arec)=$app->getOnlyFirst(qw(id cistatusid));

   if (!defined($arec)){
      push(@qmsg,"invalid application reference");
   }
   else{
      if ($arec->{cistatusid} ne "4" &&
          $arec->{cistatusid} ne "3"){
          push(@qmsg,"invalid CI-State for application");
      }
   }
   my $azureSubscriptionId=$rec->{srcid};  
   { 
      my $chk=getModuleObject($self->getParent->Config(),"azure::subscription");
      $chk->SetFilter({subscriptionId=>$azureSubscriptionId});
      my @acc=$chk->getHashList(qw(id subscriptionId));
      if ($#acc==-1){
         push(@qmsg,"AZURE account invalid or not accessable");
      }
   }

   if ($#qmsg==-1){
      my $par=getModuleObject($self->getParent->Config(),
                              "azure::virtualMachine");

      $par->SetFilter({subscriptionId=>$azureSubscriptionId});

      my @l=$par->getHashList(qw(id cdate));

      my @id;
      my %srcid;
      foreach my $irec (@l){
         push(@id,$irec->{id});
         $srcid{$irec->{id}}={
            cdate=>$irec->{cdate}
         };
      }
      my $sys=getModuleObject($self->getParent->Config(),"itil::system");

      $sys->SetFilter([
         {
            srcid=>[keys(%srcid)]
         },
         {
            srcsys=>'AZURE',
            itcloudareaid=>$rec->{id},
            cistatusid=>"<6"
         }]
      );
      my @cursys=$sys->getHashList(qw(id srcid cistatusid));

      my @delsys;
      my @inssys;
      my @updsys;

      foreach my $sysrec (@cursys){
         my $srcid=$sysrec->{srcid};
         if (exists($srcid{$srcid})){
            if ($sysrec->{cistatusid} ne "4"){
               $srcid{$srcid}->{op}="upd";
            }
            else{
               $srcid{$srcid}->{op}="ok";
            }
         }
      }
      foreach my $sysrec (@cursys){
         my $srcid=$sysrec->{srcid};
         if (!exists($srcid{$srcid}) || !exists($srcid{$srcid}->{op})){
            push(@delsys,$srcid);
         }
      }
      foreach my $srcid (keys(%srcid)){
         if (!exists($srcid{$srcid}) || !exists($srcid{$srcid}->{op})){
            push(@inssys,$srcid);
         }
         elsif($srcid{$srcid}->{op} eq "upd"){
            push(@updsys,$srcid);
         }
      }

      $par->ResetFilter();
      foreach my $srcid (@inssys){
         $par->ResetFilter();
         $par->SetFilter({id=>$srcid}); # reread record to prevent error msg
                                        # on fast deleted systems
         my @l=$par->getHashList(qw(name
                                    id zone vmId
                                    subscriptionId ipaddresses ));
         foreach my $importrec (@l){  
            my $bk=$par->Import({importrec=>$importrec});
            if (!defined($bk)){
               push(@qmsg,"fail import: ".$importrec->{id});
            } 
            else{
               push(@qmsg,"import: ".$importrec->{id});
            }
         }
      }
      if (keys(%srcid) &&   # ensure, restcall get at least one result
          $#delsys!=-1){
         $sys->ResetFilter();
         $sys->SetFilter(srcid=>\@delsys);
         my $op=$sys->Clone();
         foreach my $rec ($sys->getHashList(qw(ALL))){
            $op->ValidatedUpdateRecord($rec,{cistatusid=>6},{id=>\$rec->{id}});
         }
      }
   }

   my @result=$self->HandleQRuleResults("AZURE",
                 $dataobj,$rec,$checksession,
                 \@qmsg,\@dataissue,\$errorlevel,$wfrequest,$forcedupd);

   return(@result);
}



1;
