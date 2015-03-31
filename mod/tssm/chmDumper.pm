package tssm::chmDumper;
#  W5Base Framework
#  Copyright (C) 2010  Hartmut Vogler (it@guru.de)
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
use kernel::Field::DataDump;
@ISA=qw(kernel::App::Web::Listedit kernel::DataObj::DB);

sub new
{
   my $type=shift;
   my %param=@_;
   $param{MainSearchFieldLines}=4;
   my $self=bless($type->SUPER::new(%param),$type);
   
   $self->AddFields(
      new kernel::Field::Linenumber(
                name          =>'linenumber',
                htmlwidth     =>'1%',
                label         =>'No.'),

      new kernel::Field::Id(
                name          =>'changenumber',
                sqlorder      =>'desc',
                searchable    =>1,
                label         =>'Change No.',
                htmlwidth     =>'20',
                align         =>'left',
                dataobjattr   =>'cm3rm1.dh_number'),

      new kernel::Field::Text(
                name          =>'name',
                label         =>'Brief Description',
                ignorecase    =>1,
                dataobjattr   =>'cm3rm1.brief_description'),

      new kernel::Field::Date(
                name          =>'plannedstart',
                timezone      =>'CET',
                label         =>'Planed Start',
                dataobjattr   =>'cm3rm1.planned_start'),

      new kernel::Field::Date(
                name          =>'plannedend',
                timezone      =>'CET',
                label         =>'Planed End',
                dataobjattr   =>'cm3rm1.planned_end'),

      new kernel::Field::DataDump(
                name          =>'fulldump',
                depend        =>['changenumber'],
                label         =>'DataDump',
                sqldepend     =>[
                   'dh_cm3rm1'=>{
                       dbname=>'tssm',
                       joinon=>['changenumber'=>'dh_number'] 
                   },
                   'dh_cm3ra1'=>{
                       dbname=>'tssm',
                       joinon=>['changenumber'=>'dh_number'] 
                   },
                   'dh_cm3ra2'=>{
                       dbname=>'tssm',
                       joinon=>['changenumber'=>'dh_number'] 
                   },
                   'dh_cm3ra6'=>{
                       dbname=>'tssm',
                       joinon=>['changenumber'=>'dh_number'] 
                   },
                   'dh_cm3ra7'=>{
                       dbname=>'tssm',
                       joinon=>['changenumber'=>'dh_number'] 
                   },
                   'dh_cm3ra9'=>{
                       dbname=>'tssm',
                       joinon=>['changenumber'=>'dh_number'] 
                   },
                   'dh_cm3ra10'=>{
                       dbname=>'tssm',
                       joinon=>['changenumber'=>'dh_number'] 
                   }
                ],
                onRawValue    =>\&DataDumpSQL),
   );

   $self->setDefaultView(qw(linenumber changenumber 
                            fulldump));
   return($self);
}


sub DataDumpSQL
{
   my $self=shift;
   my $current=shift;
   my %rec=();

   my $depend=$self->{depend};
   my @depend;
   if (ref($depend) eq "ARRAY"){
      @depend=@$depend;
   }
   my @sqlctrl=@{$self->{sqldepend}};
   while(my $k=shift(@sqlctrl)){
     my $ctrl=shift(@sqlctrl);
     my $fields="*";
     my $from=$k;
     my $where="";
     $from=$ctrl->{from}   if (exists($ctrl->{from}));
     $fields=$ctrl->{fields}     if (exists($ctrl->{fields}));
     $where=$ctrl->{where} if (exists($ctrl->{where}));
     if (exists($ctrl->{joinon}) && ref($ctrl->{joinon}) eq "ARRAY"){
        my $srcval=$current->{$ctrl->{joinon}->[0]};
        my $dstname=$ctrl->{joinon}->[1];
        $where="(".$where.") and " if ($where ne "");
        $where.=$dstname."='".$srcval."'";
     }
     my $cmd="select ".$fields." from ".$from." where ".$where;
     $cmd=$ctrl->{cmd} if (exists($ctrl->{cmd}));
     my $workdb=new kernel::database($self->getParent,$ctrl->{dbname});
     if ($workdb->Connect()){
        my @l=$workdb->getHashList($cmd);
        if ($workdb->Ping()){
           $rec{$k}={'SQLcommand'=>$cmd,
                     'SQLdbname'=>$ctrl->{dbname},
                     'Result'=>\@l};
           $workdb->Disconnect();
        }
     }
     if (!exists($rec{$k})){
        $rec{$k}={SQLerror=>'query problem',
                  SQLcmd=>$cmd};
     }
   }
   return(\%rec);
}



sub Initialize
{
   my $self=shift;

   my @result=$self->AddDatabase(DB=>new kernel::database($self,"tssm"));
   return(@result) if (defined($result[0]) eq "InitERROR");

   $self->{use_distinct}=0;
   return(1) if (defined($self->{DB}));
   return(0);
}


sub getRecordImageUrl
{
   my $self=shift;
   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
   return("../../../public/itil/load/chm.jpg?".$cgi->query_string());
}

sub getSqlFrom
{
   my $self=shift;
   my $from="dh_cm3rm1 cm3rm1";
   return($from);
}

sub initSqlWhere
{
   my $self=shift;
   my $where="(cm3rm1.last='t' or cm3rm1.last is null)";
   return($where);
}

sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   return if (!$self->IsMemberOf("admin"));
   return("ALL");
}

sub isWriteValid
{
   my $self=shift;
   my $rec=shift;
   return(undef);
}







1;
