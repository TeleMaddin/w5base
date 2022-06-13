package leanix::event::leanixDataLoad;
#  W5Base Framework
#  Copyright (C) 2022  Hartmut Vogler (it@guru.de)
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
use kernel::Event;
use UUID::Tiny;
@ISA=qw(kernel::Event);



sub leanixDataLoad
{
   my $self=shift;

   my $funcmgrid="11785813690001";  # Carsten
   my $databossid="15214605570000"; # Natalia
   my $mandatorid="200";

   my %db;
   my $lixbc=getModuleObject($self->Config,"leanix::BusinessCapability");
   my $lixap=getModuleObject($self->Config,"leanix::Application");
   #$lixbc->SetFilter({tags=>'BCC:* PRK:*',displayName=>'*ES-0001*'});
   $lixbc->SetFilter({tags=>'BCC:* PRK:*'});
   my @lixbcView=qw(name displayName id relations tags);
   my @l=$lixbc->getHashList(@lixbcView);

   foreach my $rec (@l){
      my $rel=$rec->{relations};
      foreach my $relrec (@$rel){
         if (!exists($db{$relrec->{dataobjToFS}}->{$relrec->{toId}})){
            $db{$relrec->{dataobjToFS}}->{$relrec->{toId}}=undef;
         }
      }
   }
   foreach my $rec (@l){
      $db{$lixbc->Self()}->{$rec->{id}}=$rec;
   }

   my $fillup=0;
   do{
      $fillup=0;
      foreach my $id (sort(keys(%{$db{'leanix::BusinessCapability'}}))){
         if (!defined($db{'leanix::BusinessCapability'}->{$id})){
            $lixbc->SetFilter({id=>\$id});
            my ($brec)=$lixbc->getOnlyFirst(@lixbcView);
            if (defined($brec)){
               $db{'leanix::BusinessCapability'}->{$id}=$brec;
               $fillup++;
            }
         }
      }
   }while($fillup==0);



   #
   # Fillup FactSheets for applications from LeanIX
   #
   foreach my $id (sort(keys(%{$db{'leanix::Application'}}))){
      if (!defined($db{'leanix::Application'}->{$id})){
         $lixap->SetFilter({id=>\$id});
         my ($arec)=$lixap->getOnlyFirst(qw(name displayName id 
                                            alias ictoid tags));
         if (defined($arec)){
            $db{'leanix::Application'}->{$id}=$arec;
         }
      }
   }
   foreach my $obj (keys(%db)){
      if (!in_array($obj,[qw(leanix::Application 
                             leanix::BusinessCapability)])){
         delete($db{$obj});
      }
   }

   #
   # Loading W5BaseIDs of applications
   #
   my $w5appl=getModuleObject($self->Config,"TS::appl");
   foreach my $id (sort(keys(%{$db{'leanix::Application'}}))){
      if (defined($db{'leanix::Application'}->{$id})){
         my $rec=$db{'leanix::Application'}->{$id};
         if ($rec->{ictoid} ne ""){
            #msg(INFO,"loading $rec->{ictoid}");
            $w5appl->ResetFilter();
            $w5appl->SetFilter({
               ictono=>$rec->{ictoid},
               cistatusid=>'4',opmode=>\'prod'
            });
            my @l=$w5appl->getHashList(qw(name id ));
            if ($#l!=-1){
               $rec->{w5appl}=\@l;
            }
         }
      }
   }


   #
   # Create virtual object leanix::ProcessChain
   #
   foreach my $fsobj (qw(leanix::Application leanix::BusinessCapability)){
      foreach my $fsrec (values(%{$db{$fsobj}})){
         my $tags=$fsrec->{tags};
         $tags=[$tags] if (ref($tags) ne "ARRAY");
         my @tags=@{$tags};
         my @prc=grep(/^PRK:/,@tags);
         foreach my $prc (@prc){
            my $uuid=UUID::Tiny::create_uuid_as_string(UUID_V5,$prc);
            if (!exists($db{'leanix::ProcessChain'}->{$uuid})){
               if (my ($num,$name)=$prc=~m/^PRK:\s*(\d+)\s*(.*)$/){
                  $db{'leanix::ProcessChain'}->{$uuid}={
                     id=>$uuid,
                     displayName=>$prc,
                     name=>$name,
                     shortname=>$num,
                     relations=>[],
                  }
               }
            }
            push(@{$db{'leanix::ProcessChain'}->{$uuid}->{relations}},{
               dataobjToFS=>$fsobj,
               toId=>$fsrec->{id},
            });
         }
      }
   }


   # create shortnames
   foreach my $fsobj (qw(leanix::BusinessCapability)){
      foreach my $fsrec (values(%{$db{$fsobj}})){
         my $namestr=$fsrec->{name};
         if (my ($sh,$n)=$namestr=~m/^([A-Z]+-[0-9]+)+\s*[-]{0,1}\s*(.*)$/){
            $fsrec->{name}=$n;
            $fsrec->{shortname}=$sh;
         }
      }
   }




   
   #
   # Create BusinessServices in W5Base/Darwin
   #
   if (1){
      my $w5bs=getModuleObject($self->Config,"itil::businessservice");
      my $srcsys='leanix::BusinessCapability';
      foreach my $lixrec (values(%{$db{$srcsys}})){
         my $srcid=$lixrec->{id};
         $w5bs->ResetFilter();
         $w5bs->SetFilter({srcid=>\$srcid,srcsys=>\$srcsys});
         my ($w5rec)=$w5bs->getOnlyFirst(qw(ALL));
         my $w5id;
         if (!defined($w5rec)){
            my $bk=$w5bs->ValidatedInsertRecord({
               nature=>'BC',
               shortname=>$lixrec->{shortname},
               description=>$lixrec->{description},
               name=>$lixrec->{name},
               cistatusid=>'4',
               databossid=>$databossid,
               mandatorid=>$mandatorid,
               funcmgrid=>$funcmgrid,
               srcsys=>$srcsys,
               srcid=>$srcid
            });
            if ($bk){
               $w5bs->ResetFilter();
               $w5bs->SetFilter({id=>\$bk});
               ($w5rec)=$w5bs->getOnlyFirst(qw(ALL));
            }
         }
         $w5id=$w5rec->{id};
         my %upd;
         if ($w5rec->{cistatusid} ne "4"){
            $upd{cistatusid}=4;
         }
         if ($w5rec->{mandatorid} eq ""){
            $upd{mandatorid}=$mandatorid;
         }
         if ($w5rec->{databossid} eq ""){
            $upd{databossid}=$databossid;
         }
         if ($w5rec->{funcmgrid} eq ""){
            $upd{funcmgrid}=$funcmgrid;
         }
         if ($w5rec->{description} ne $lixrec->{description}){
            $upd{description}=$lixrec->{description};
         }
         if (keys(%upd)){
            $w5bs->ValidatedUpdateRecord($w5rec,\%upd,{id=>\$w5id});
         }
         $lixrec->{w5id}=$w5id;
      }
   }

   #
   # Create ProcessCains in W5Base/Darwin
   #
   if (1){
      my $w5bs=getModuleObject($self->Config,"itil::businessservice");
      my $srcsys='leanix::ProcessChain';
      foreach my $lixrec (values(%{$db{$srcsys}})){
         my $srcid=$lixrec->{id};
         $w5bs->ResetFilter();
         $w5bs->SetFilter({srcid=>\$srcid,srcsys=>\$srcsys});
         my ($w5rec)=$w5bs->getOnlyFirst(qw(ALL));
         my $w5id;
         if (!defined($w5rec)){
            my $bk=$w5bs->ValidatedInsertRecord({
               nature=>'PRC',
               shortname=>$lixrec->{shortname},
               description=>$lixrec->{description},
               name=>$lixrec->{name},
               cistatusid=>'4',
               databossid=>$databossid,
               mandatorid=>$mandatorid,
               funcmgrid=>$funcmgrid,
               srcsys=>$srcsys,
               srcid=>$srcid
            });
            if ($bk){
               $w5bs->ResetFilter();
               $w5bs->SetFilter({id=>\$bk});
               ($w5rec)=$w5bs->getOnlyFirst(qw(ALL));
            }
         }
         $w5id=$w5rec->{id};
         my %upd;
         if ($w5rec->{cistatusid} ne "4"){
            $upd{cistatusid}=4;
         }
         if ($w5rec->{description} ne $lixrec->{description}){
            $upd{description}=$lixrec->{description};
         }
         if ($w5rec->{mandatorid} eq ""){
            $upd{mandatorid}=$mandatorid;
         }
         if ($w5rec->{databossid} eq ""){
            $upd{databossid}=$databossid;
         }
         if ($w5rec->{funcmgrid} eq ""){
            $upd{funcmgrid}=$funcmgrid;
         }
         if (keys(%upd)){
            $w5bs->ValidatedUpdateRecord($w5rec,\%upd,{id=>\$w5id});
         }
         $lixrec->{w5id}=$w5id;
      }
   }

   #
   # Create ProcessCains Relations in W5Base/Darwin
   #
   if (1){
      my $w5bs=getModuleObject($self->Config,"itil::businessservice");
      my $w5bsc=getModuleObject($self->Config,"itil::lnkbscomp");
      my $srcsys='leanix::ProcessChain';
      foreach my $srcsys (qw(leanix::ProcessChain leanix::BusinessCapability)){
         foreach my $lixrec (values(%{$db{$srcsys}})){
            my $srcid=$lixrec->{id};
            my $w5id=$lixrec->{w5id};
            my $w5rec;
       
            if ($w5id ne ""){
               $w5bs->ResetFilter();
               $w5bs->SetFilter({id=>\$w5id});
               ($w5rec)=$w5bs->getOnlyFirst(qw(name id relations));
            }
            my @currel=@{$w5rec->{servicecomp}};
            foreach my $lixrel (@{$lixrec->{relations}}){
               # ign relToParent relBusinessCapabilityToITComponent
               if (!in_array($lixrel->{type},[
                     qw(relBusinessCapabilityToProcess
                        relBusinessCapabilityToApplication
                        relToChild )])){
                  next;
               }
               if ($lixrel->{dataobjToFS} eq "leanix::BusinessCapability"){
                  my $lixBcRec=
                       $db{'leanix::BusinessCapability'}->{$lixrel->{toId}};
                  if ($lixBcRec->{w5id} ne ""){
                     my $targetbsid=$lixBcRec->{w5id};
                     my $found=0;
                     foreach my $currel (@currel){
                        if ($currel->{objtype} eq "itil::businessservice" &&
                            $currel->{obj1id} eq $targetbsid){
                           $found++;
                        }
                     }
                     if (!$found){
                        $w5bsc->ValidatedInsertRecord({
                           businessserviceid=>$w5id,
                           objtype=>'itil::businessservice', 
                           obj1id=>$targetbsid
                        });
                     }
                  }
               }
               if ($lixrel->{dataobjToFS} eq "leanix::Application"){
                  my $lixApplRec=$db{'leanix::Application'}->{$lixrel->{toId}};
                  if (ref($lixApplRec->{w5appl}) eq
                      "ARRAY"){
                     my @a=@{$lixApplRec->{w5appl}};
                     foreach my $a (@a){
                        my $found=0;
                        foreach my $currel (@currel){
                           if ($currel->{objtype} eq "itil::appl" &&
                               $currel->{obj1id} eq $a->{id}){
                              $found++;
                           }
                        }
                        if (!$found){
                           $w5bsc->ValidatedInsertRecord({
                              businessserviceid=>$w5id,
                              objtype=>'itil::appl', 
                              obj1id=>$a->{id}
                           });
                        }
                     }
                  }
               }
            }
         }
      }
   }





   

   #print Dumper(\@l);
   #print Dumper($db{'leanix::Application'});
   #print Dumper($db{'leanix::ProcessChain'});

   printf STDERR ("n leanix::Application=%d\n",
                   scalar(keys(%{$db{'leanix::Application'}})));
   printf STDERR ("n leanix::BusinessCapability=%d\n",
                   scalar(keys(%{$db{'leanix::BusinessCapability'}})));
   printf STDERR ("n leanix::ProcessChain=%d\n",
                   scalar(keys(%{$db{'leanix::ProcessChain'}})));




   return({exitcode=>0,exitmsg=>'ok'});
}


1;
