package CRaS::event::CRaSexpireCheck;
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
use kernel::Event;

@ISA=qw(kernel::Event);



sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);

   return($self);
}




sub CRaSexpireCheck
{
   my $self=shift;

   my $obj=$self->getPersistentModuleObject("csr","CRaS::csr");

   $obj->SetFilter({state=>'4',ssslenddate=>"<now+14d"});
   my $wobj=$obj->Clone();
   foreach my $rec ($obj->getHashList(qw(ALL))){
      if (1| $rec->{sslexpnotify1} eq ""){
         if ($obj->doNotify($rec->{id},"CERTEXPIRE1")){
            $wobj->ValidatedUpdateRecord($rec,{
               sslexpnotify1=>NowStamp("en"),
               mdate=>$rec->{mdate}
            },id=>\$rec->{id});
         }
      }
      else{
         if ($rec->{sslexpnotify2} eq ""){
            if ($obj->doNotify($rec->{id},"CERTEXPIRE2")){
               $wobj->ValidatedUpdateRecord($rec,{
                  sslexpnotify2=>NowStamp("en"),
                  mdate=>$rec->{mdate}
               },id=>\$rec->{id});
            }
         }
      }
      #print Dumper($rec);

   }
   return({exitcode=>0});
}



