package temporal::tspan;
#  W5Base Framework
#  Copyright (C) 2016  Hartmut Vogler (it@guru.de)
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
use kernel::DataObj::DB;
use kernel::Field;
@ISA=qw(kernel::App::Web::Listedit kernel::DataObj::DB);

sub new
{
   my $type=shift;
   my %param=@_;
   $param{MainSearchFieldLines}=3 if (!exists($param{MainSearchFieldLines}));
   my $self=bless($type->SUPER::new(%param),$type);

   $self->AddFields(
      new kernel::Field::Linenumber(
                name          =>'linenumber',
                label         =>'No.'),

      new kernel::Field::Id(
                name          =>'id',
                sqlorder      =>'desc',
                htmldetail    =>sub{
                   my ($self,$mode,%param)=@_;
                   return(defined($param{current}) ? 1 : 0);
                },
                label         =>'W5BaseID',
                dataobjattr   =>'tspanentry.id'),
                                                  
      new kernel::Field::TextDrop(
                name          =>'planname',
                vjointo       =>'temporal::plan',
                vjoinon       =>['planid'=>'id'],
                vjoindisp     =>'name',
                label         =>'time plan',
                dataobjattr   =>'timeplan.name'),

      new kernel::Field::Interface(
                name          =>'planid',
                label         =>'timeplan id',
                dataobjattr   =>'tspanentry.timeplanref'),

      new kernel::Field::Text(
                name          =>'name',
                label         =>'tspanentry name',
                dataobjattr   =>'tspanentry.name'),

      new kernel::Field::Date(
                name          =>'tfrom',
                label         =>'from',
                dataobjattr   =>'tspanentry.tfrom'),

      new kernel::Field::Date(
                name          =>'tto',
                label         =>'to',
                dataobjattr   =>'tspanentry.tto'),

      new kernel::Field::TRange(
                name          =>'trange',
                label         =>'Range-Filter',
                depend        =>['span_s','span_m','span_e']),

      new kernel::Field::Textarea(
                name          =>'comments',
                label         =>'Comments',
                searchable    =>0,
                dataobjattr   =>'tspanentry.comments'),

      new kernel::Field::CDate(
                name          =>'cdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Creation-Date',
                dataobjattr   =>'tspanentry.createdate'),
                                                  
      new kernel::Field::MDate(
                name          =>'mdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Modification-Date',
                dataobjattr   =>'tspanentry.modifydate'),

      new kernel::Field::Creator(
                name          =>'creator',
                group         =>'source',
                label         =>'Creator',
                dataobjattr   =>'tspanentry.createuser'),

      new kernel::Field::Owner(
                name          =>'owner',
                group         =>'source',
                label         =>'last Editor',
                dataobjattr   =>'tspanentry.modifyuser'),

      new kernel::Field::Editor(
                name          =>'editor',
                group         =>'source',
                label         =>'Editor Account',
                dataobjattr   =>'tspanentry.editor'),

      new kernel::Field::RealEditor(
                name          =>'realeditor',
                group         =>'source',
                label         =>'real Editor Account',
                dataobjattr   =>'tspanentry.realeditor'),

      new kernel::Field::Interface(
                name          =>'replkeypri',
                group         =>'source',
                label         =>'primary sync key',
                dataobjattr   =>"tspanentry.modifydate"),

      new kernel::Field::Interface(
                name          =>'replkeysec',
                group         =>'source',
                label         =>'secondary sync key',
                dataobjattr   =>"lpad(tspanentry.id,35,'0')"),

      new kernel::Field::Date(
                name          =>'span_s',
                noselect      =>'1',
                uivisible     =>0,
                htmldetail    =>0,
                searchable    =>0,
                dataobjattr   =>'tsrange.s'),

      new kernel::Field::Date(
                name          =>'span_m',
                noselect      =>'1',
                uivisible     =>0,
                htmldetail    =>0,
                searchable    =>0,
                dataobjattr   =>'tsrange.m'),

      new kernel::Field::Date(
                name          =>'span_e',
                noselect      =>'1',
                uivisible     =>0,
                htmldetail    =>0,
                searchable    =>0,
                dataobjattr   =>'tsrange.e'),



   );
   $self->setDefaultView(qw(linenumber planname name tfrom tto mdate));
   $self->setWorktable("tspanentry");
   return($self);
}

sub initSearchQuery
{
   my $self=shift;
#   if (!defined(Query->Param("search_cistatus"))){
#     Query->Param("search_cistatus"=>
#                  "\"!".$self->T("CI-Status(6)","base::cistatus")."\"");
#   }
}



sub getSqlFrom
{
   my $self=shift;
   my $mode=shift;
   my @flt=@_;
   my ($worktable,$workdb)=$self->getWorktable();
   my $from="$worktable join timeplan ".
            "on $worktable.timeplanref=timeplan.id ";

   my $spanfltfound=0;
   my @spanflts=qw(span_s span_m span_e);

   foreach my $flt (@flt){
      if (ref($flt) eq "HASH"){
         if (in_array([keys(%$flt)],\@spanflts)){
            $spanfltfound++;
         }
      }
      if (ref($flt) eq "ARRAY"){
         foreach my $sflt (@$flt){
            if (ref($sflt) eq "HASH"){
               if (in_array([keys(%$sflt)],\@spanflts)){
                  $spanfltfound++;
               }
            }
         }
      }
   }
   #print STDERR Dumper(\@flt);
   if ($spanfltfound){
      $from="tsrange join $worktable ".
            "on tsrange.tspanentryid=$worktable.id ".
            "join timeplan ".
            "on $worktable.timeplanref=timeplan.id ";

   }

   return($from);
}




sub getDetailBlockPriority                # posibility to change the block order
{
   my $self=shift;
   return(qw(header default source));
}



sub SetFilter
{
   my $self=shift;
   my @flt=@_;
   if ($self->getField("trange")->SetFilter(\@flt)){; # expand filter for 
                                                      # timerange handling 
      return($self->SUPER::SetFilter(@flt));
   }
   return(undef);
}






sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;

   if ((my $v=effVal($oldrec,$newrec,"name"))=~m/^\s*$/){
      $self->LastMsg(ERROR,"invalid internal name");
      return(undef);
   }

   return(1);
}


sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   return("header","default") if (!defined($rec) && $self->IsMemberOf("admin"));
   return("ALL");
}

sub isWriteValid
{
   my $self=shift;
   my $rec=shift;
   return("default") if ($self->IsMemberOf("admin"));
   return(undef);
}


sub isCopyValid
{
   my $self=shift;
   my $copyfrom=shift;
   return(1);
}






1;
