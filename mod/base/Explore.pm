package base::Explore;
#  W5Base Framework
#  Copyright (C) 2017  Hartmut Vogler (it@guru.de)
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
use kernel::App::Web;
use JSON;
@ISA=qw(kernel::App::Web);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);
   $self->LoadSubObjsOnDemand("Explore","Explore");
   return($self);
}

sub getValidWebFunctions
{
   my ($self)=@_;
   return(qw(Main jsApplets));
}


#
# Explore Engine
#

sub Main
{
   my ($self)=@_;

   print $self->HttpHeader("text/html",charset=>'UTF-8');

   my $getAppTitleBar=$self->getAppTitleBar();
   my $BASE=$ENV{REQUEST_URI};
   $BASE=~s#/Explore/Main.*?$#/Explore/Main#;

   my $opt={
      static=>{
         BASE=>$BASE
      }
   };

   my $prog=$self->getParsedTemplate("tmpl/base.Explore.js",$opt);
   utf8::encode($prog);
   print($prog);
}

sub jsApplets
{
   my $self=shift;
   my $lang=$self->Lang();

   print $self->HttpHeader("text/javascript");

   my $appletcall;
   if (defined(Query->Param("FunctionPath"))){
      $appletcall=Query->Param("FunctionPath");
   }
   $appletcall=~s/^\///;
   $appletcall=~s/\//::/g;

   printf("(function(window, document, undefined){\n");
   if ($appletcall ne ""){
      if (exists($self->{Explore}->{$appletcall})){
         sleep(2);
         print($self->{Explore}->{$appletcall}->getJSObjectClass($self,$lang));
      }
   }
   else{
      my $jsengine=new JSON();
      foreach my $sobj (values(%{$self->{Explore}})){
         my $d;
         if ($sobj->can("getObjectInfo")){
            $d=$sobj->getObjectInfo($self,$lang);
         }
         if (defined($d)){
            my $selfname=$sobj->Self();
            my $jsdata=$jsengine->encode($d);
            printf("ClassAppletLib['%s']={desc:%s};\n",$selfname,$jsdata);
         }
      }
   }
   printf("})(this,document);\n\n");
}


1;
