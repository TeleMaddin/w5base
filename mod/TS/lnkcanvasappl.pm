package TS::lnkcanvasappl;
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
use kernel::App::Web;
use kernel::DataObj::DB;
use kernel::Field;
@ISA=qw(kernel::App::Web::Listedit kernel::DataObj::DB);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);

   

   $self->AddFields(
      new kernel::Field::TextDrop(
                name          =>'canvas',
                htmlwidth     =>'360px',
                label         =>'Canvas Object',
                vjointo       =>'TS::canvas',
                vjoinon       =>['canvasid'=>'id'],
                vjoindisp     =>'fullname',
                dataobjattr   =>'canvas.name'),
                                                   
      new kernel::Field::Interface(
                name          =>'canvasid',
                label         =>'CanvasID',
                dataobjattr   =>'lnkcanvas.canvasid'),

      new kernel::Field::Interface(
                name          =>'canvascanvasid',
                label         =>'Canvas CanvasID',
                dataobjattr   =>'canvas.canvasid'),

      new kernel::Field::Text(
                name          =>'ictono',
                htmldetail    =>0,
                uploadable    =>0,
                label         =>'ICTO-ID',
                dataobjattr   =>'lnkcanvas.ictono'),

      new kernel::Field::Text(
                name          =>'appl',
                htmldetail    =>0,
                uploadable    =>0,
                label         =>'Application',
                dataobjattr   =>'appl.name'),

      new kernel::Field::Interface(
                name          =>'applid',
                label         =>'ApplID',
                dataobjattr   =>'appl.id'),

      new kernel::Field::Percent(
                name          =>'fraction',
                label         =>'Fraction',
                searchable    =>0,
                default       =>'100',
                htmlwidth     =>'60px',
                dataobjattr   =>'lnkcanvas.fraction'),

      new kernel::Field::TextDrop(
                name          =>'vou',
                htmlwidth     =>'100px',
                label         =>'virtual Org-Unit',
                htmlwidth     =>'160px',
                vjointo       =>'TS::vou',
                vjoinon       =>['vouid'=>'id'],
                vjoindisp     =>'fullname',
                dataobjattr   =>'vou.name'),
                                                   
      new kernel::Field::TextDrop(
                name          =>'voushort',
                htmlwidth     =>'100px',
                label         =>'virtual Org-Unit Short',
                htmlwidth     =>'160px',
                vjointo       =>'TS::vou',
                vjoinon       =>['vouid'=>'id'],
                vjoindisp     =>'name',
                dataobjattr   =>'vou.shortname'),
                                                   
      new kernel::Field::Text(
                name          =>'vougrpname',
                label         =>'virtual Org-Unit Group',
                dataobjattr   =>'grp.fullname'),
                                                   
      new kernel::Field::Interface(
                name          =>'vougrpid',
                label         =>'virtual Org-Unit GroupID',
                dataobjattr   =>'grp.grpid'),
                                                   
      new kernel::Field::Interface(
                name          =>'vouid',
                label         =>'VouID',
                dataobjattr   =>'lnkcanvas.vouid'),

      new kernel::Field::Text(
                name          =>'canvascanvasid',
                label         =>'CanvasID',
                dataobjattr   =>'canvas.canvasid'),

      new kernel::Field::Interface(
                name          =>'canvasownerid',
                label         =>'Canvas Owner',
                dataobjattr   =>'canvas.leader'),

      new kernel::Field::Interface(
                name          =>'canvasowneritid',
                label         =>'Canvas OwnerIT',
                dataobjattr   =>'canvas.leaderit'),
   );
   $self->setDefaultView(qw(canvascanvasid canvas fraction 
                            ictono vou voushort vougrpname appl));
   $self->setWorktable("lnkcanvas");
   return($self);
}


sub getSqlFrom
{
   my $self=shift;
   my $from="appl ".
            "left outer join lnkcanvas ".
            "on lnkcanvas.ictono=appl.ictono ".
            "left outer join vou ".
            "on lnkcanvas.vouid=vou.id ".
            "left outer join grp ".
            "on grp.srcid=vou.id and grp.srcsys='TS::vou' ".
            "left outer join canvas ".
            "on lnkcanvas.canvasid=canvas.id ";
   return($from);
}

sub initSqlWhere
{
   my $self=shift;
   my $mode=shift;
   return(undef) if ($mode eq "delete");
   return(undef) if ($mode eq "insert");
   return(undef) if ($mode eq "update");
   my $where="appl.cistatus=4";
   return($where);
}



sub isQualityCheckValid
{
   my $self=shift;
   my $rec=shift;
   return(0);
}



sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   return("header","default") if (!defined($rec));
   return("ALL");
}

sub isWriteValid
{
   my $self=shift;
   my $rec=shift;
   return(undef);
}

sub getDetailBlockPriority
{
   my $self=shift;
   return($self->SUPER::getDetailBlockPriority(@_),
          qw(default source ));
}



1;
