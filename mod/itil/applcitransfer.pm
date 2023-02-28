package itil::applcitransfer;
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
use itil::lib::Listedit;
@ISA=qw(itil::lib::Listedit);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);

   $self->AddFields(
      new kernel::Field::Linenumber(
                name          =>'linenumber',
                label         =>'No.'),

      new kernel::Field::Id(
                name          =>'id',
                sqlorder      =>'desc',
                label         =>'W5BaseID',
                group         =>'source',
                dataobjattr   =>'applcitransfer.id'),

      new kernel::Field::RecordUrl(),

      new kernel::Field::TextDrop(
                name          =>'eappl',
                htmlwidth     =>'250px',
                label         =>'emitting Application',
                vjoineditbase =>{'cistatusid'=>"4"},
                vjointo       =>'itil::appl',
                vjoinon       =>['eapplid'=>'id'],
                vjoindisp     =>'name'),

      new kernel::Field::Interface(
                name          =>'eapplid',
                label         =>'emitting Application ID',
                selectfix     =>1,
                dataobjattr   =>'applcitransfer.eappl'),

      new kernel::Field::TextDrop(
                name          =>'cappl',
                htmlwidth     =>'250px',
                label         =>'collecting Application',
                vjoineditbase =>{'cistatusid'=>"4"},
                vjointo       =>'itil::appl',
                vjoinon       =>['capplid'=>'id'],
                vjoindisp     =>'name'),

      new kernel::Field::Interface(
                name          =>'capplid',
                label         =>'collecting Application ID',
                selectfix     =>1,
                dataobjattr   =>'applcitransfer.cappl'),


      new kernel::Field::Textarea(
                name          =>'comments',
                label         =>'Comments',
                searchable    =>0,
                dataobjattr   =>'applcitransfer.comments'),
                                                   
      new kernel::Field::Textarea(
                name          =>'configitems',
                label         =>'Config-Item adresses',
                group         =>'transitems',
                searchable    =>0,
                dataobjattr   =>'applcitransfer.configitems'),




      new kernel::Field::Contact(
                name          =>'eapplackuser',
                group         =>'eapprove',
                htmldetail    =>'NotEmpty',
                label         =>'emitting application approver',
                vjoinon       =>'eapplackuserid'),

      new kernel::Field::Interface(
                name          =>'eapplackuserid',
                group         =>'eapprove',
                htmldetail    =>'NotEmpty',
                label         =>'emitting application approve userid',
                dataobjattr   =>'applcitransfer.eappl_ack_user'),

      new kernel::Field::Date(
                name          =>'eapplackdate',
                group         =>'eapprove',
                htmldetail    =>'NotEmpty',
                label         =>'emitting application approve date',
                dataobjattr   =>'applcitransfer.eappl_ack_date'),

      new kernel::Field::Textarea(
                name          =>'eapplackcmnt',
                group         =>'eapprove',
                htmldetail    =>'NotEmpty',
                label         =>'emitting application approve comment',
                dataobjattr   =>'applcitransfer.eappl_ack_cmnt'),



      new kernel::Field::Contact(
                name          =>'capplackuser',
                group         =>'capprove',
                htmldetail    =>'NotEmpty',
                label         =>'collecting application approver',
                vjoinon       =>'capplackuserid'),

      new kernel::Field::Interface(
                name          =>'capplackuserid',
                group         =>'capprove',
                htmldetail    =>'NotEmpty',
                label         =>'collecting application approve userid',
                dataobjattr   =>'applcitransfer.cappl_ack_user'),

      new kernel::Field::Date(
                name          =>'capplackdate',
                group         =>'capprove',
                htmldetail    =>'NotEmpty',
                label         =>'collecting application approve date',
                dataobjattr   =>'applcitransfer.cappl_ack_date'),

      new kernel::Field::Textarea(
                name          =>'capplackcmnt',
                group         =>'capprove',
                htmldetail    =>'NotEmpty',
                label         =>'collecting application approve comment',
                dataobjattr   =>'applcitransfer.cappl_ack_cmnt'),

















                                                   
      new kernel::Field::Text(
                name          =>'srcsys',
                group         =>'source',
                label         =>'Source-System',
                dataobjattr   =>'applcitransfer.srcsys'),
                                                   
      new kernel::Field::Text(
                name          =>'srcid',
                group         =>'source',
                label         =>'Source-Id',
                dataobjattr   =>'applcitransfer.srcid'),
                                                   
      new kernel::Field::Date(
                name          =>'srcload',
                group         =>'source',
                label         =>'Source-Load',
                dataobjattr   =>'applcitransfer.srcload'),

      new kernel::Field::CDate(
                name          =>'cdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Creation-Date',
                dataobjattr   =>'applcitransfer.createdate'),
                                                  
      new kernel::Field::MDate(
                name          =>'mdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Modification-Date',
                dataobjattr   =>'applcitransfer.modifydate'),

      new kernel::Field::Interface(
                name          =>'replkeypri',
                group         =>'source',
                label         =>'primary sync key',
                dataobjattr   =>"applcitransfer.modifydate"),

      new kernel::Field::Interface(
                name          =>'replkeysec',
                group         =>'source',
                label         =>'secondary sync key',
                dataobjattr   =>"lpad(applcitransfer.id,35,'0')"),

      new kernel::Field::Creator(
                name          =>'creator',
                group         =>'source',
                label         =>'Creator',
                dataobjattr   =>'applcitransfer.createuser'),

      new kernel::Field::Owner(
                name          =>'owner',
                group         =>'source',
                label         =>'last Editor',
                dataobjattr   =>'applcitransfer.modifyuser'),

      new kernel::Field::Editor(
                name          =>'editor',
                group         =>'source',
                label         =>'Editor Account',
                dataobjattr   =>'applcitransfer.editor'),

      new kernel::Field::RealEditor(
                name          =>'realeditor',
                group         =>'source',
                label         =>'real Editor Account',
                dataobjattr   =>'applcitransfer.realeditor'),
   

   );
   $self->setDefaultView(qw(eappl cappl cdate));
   $self->setWorktable("applcitransfer");
   $self->{history}={
      update=>[
         'local'
      ]
   };
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


#sub getRecordImageUrl
#{
#   my $self=shift;
#   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
#   return("../../../public/itil/load/applcitransfer.jpg?".$cgi->query_string());
#}

sub SecureValidate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;

   #printf STDERR ("fifi SecureValidate newrec=%s\n",Dumper($newrec));

   return($self->SUPER::SecureValidate($oldrec,$newrec));
}





sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;

   if (!defined($oldrec) && !exists($newrec->{configitems})){
      my $eapplid=effVal($oldrec,$newrec,"eapplid");
      my $o=getModuleObject($self->Config,"itil::appl");
      $o->SetFilter({id=>\$eapplid});
      my ($eapplrec)=$o->getOnlyFirst(qw(systems swinstances applurl));

      my %ci;
      foreach my $srec (@{$eapplrec->{systems}}){
         $ci{'itil::system::'.$srec->{systemid}}++;
      }
      foreach my $srec (@{$eapplrec->{swinstances}}){
         $ci{'itil::swinstance::'.$srec->{id}}++;
      }
      foreach my $srec (@{$eapplrec->{applurl}}){
         $ci{'itil::applurl::'.$srec->{id}}++;
      }
      $newrec->{configitems}=join("\n",sort(keys(%ci)));
   }



   my $a=$self->extractAdresses(effVal($oldrec,$newrec,"configitems"));

   print STDERR Dumper($a);
  
   return(1);
}


sub FinishWrite
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;

   if (!defined($oldrec)){
      my $eapplid=$newrec->{eapplid};
      my $capplid=$newrec->{capplid};
      my $o=getModuleObject($self->Config,"itil::appl");
      $o->SetFilter({id=>[$eapplid,$capplid]});
      my @l=$o->getHashList(qw(ALL));

      foreach my $arec (@l){
         my $direction;
         if ($eapplid==$arec->{id}){
            $direction="EApprove";
         }
         if ($capplid==$arec->{id}){
            $direction="CApprove";
         }

         $o->NotifyWriteAuthorizedContacts($arec,{},{
                  dataobj=>$self->Self,
                  emailbcc=>11634953080001,
                  dataobjid=>effVal($oldrec,$newrec,"id"),
                  emailcategory=>'CITransfer'
               },{},sub{
            my ($subject,$ntext);
            my $subject=$self->T("CI Trans $direction",'itil::applcitransfer');
            my $ntext=$self->T("Dear databoss",'kernel::QRule');
            $ntext.=",\n\n";
            $ntext.="Link:\n";

            my $baseurl=$ENV{SCRIPT_URI};
            $baseurl=~s#/(auth|public)/.*$##;
            my $jobbaseurl=$self->Config->Param("EventJobBaseUrl");
            if ($jobbaseurl ne ""){
               $jobbaseurl=~s#/$##;
               $baseurl=$jobbaseurl;
            }
            my $url=$baseurl;
            if (lc($ENV{HTTP_FRONT_END_HTTPS}) eq "on"){
               $url=~s/^http:/https:/i;
            }
            $url.="/auth/itil/applcitransfer/".$direction."/".$newrec->{id};

            $ntext.=$url."\n\n";


            $ntext.=$newrec->{configitems};
            return($subject,$ntext);
         });
      }
   }
   return(1);
}









sub extractAdresses
{
   my $self=shift;
   my $text=shift;
   my %ci;

   my @l=split(/\n/,$text);

   foreach my $line (@l){
      if (my ($obj,$id)=$line=~m/^(.*)::(.*)$/){
         $ci{$obj}=[] if (!exists($ci{$obj}));
         push(@{$ci{$obj}},$id) if (!in_array($ci{$obj},$id));
      }
   }

   return(\%ci);
}


sub FinishDelete
{
   my $self=shift;
   my $oldrec=shift;

printf STDERR ("fifi FinishDelete oldrec=%s\n",Dumper($oldrec));

   return(1);
}


sub isWriteValid
{
   my $self=shift;
   my $rec=shift;

   my $userid=$self->getCurrentUserId();
   return("default");
   return(undef);
}

sub isCopyValid
{
   my $self=shift;

   return(0);
}



sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   return("header","default") if (!defined($rec));
   return("ALL");
}


sub isQualityCheckValid
{
   my $self=shift;
   my $rec=shift;
   return(0);
}


sub getDetailBlockPriority
{
   my $self=shift;
   return( qw(header default eapprove capprove transitems source));
}



sub getValidWebFunctions
{
   my $self=shift;

   return($self->SUPER::getValidWebFunctions(@_),
           "EApprove","CApprove","Approve");
}


sub Approve
{
   my $self=shift;

   print $self->HttpHeader("text/html");
   print $self->HtmlHeader(style=>['default.css',
                                   'kernel.App.Web.css' ],
                           submodal=>1,
                           js=>['toolbox.js','subModal.js','kernel.App.Web.js'],
                           body=>1,form=>1);

   my $id=Query->Param("id");
   my $mode=Query->Param("mode");
 
   $self->ResetFilter();
   $self->SetFilter({id=>\$id});
   my ($rec)=$self->getOnlyFirst(qw(ALL));

   if (!defined($rec)){
      print $self->noAccess();
      return();
   }

   if (Query->Param("save")){
      my $doit=Query->Param("doit");
      if ($doit eq ""){
         $self->LastMsg(ERROR,"approve check box not checked");
      }
      else{
         # save approve
         my $userid=$self->getCurrentUserId();
         my %updrec;
         if ($mode eq "EApprove"){
            %updrec=(
               eapplackuserid=>$userid,
               eapplackdate=>NowStamp("en") 
            );
         }
         if ($mode eq "CApprove"){
            %updrec=(
               capplackuserid=>$userid,
               capplackdate=>NowStamp("en") 
            );
         }
         $self->ValidatedUpdateRecord($rec,\%updrec,{id=>$rec->{id}});

         # reread rec
         $self->ResetFilter();
         $self->SetFilter({id=>\$id});
         ($rec)=$self->getOnlyFirst(qw(ALL));
      }
   }



   printf("<div style=\"width:80%;min-width:200px;max-width:500px;".
          "margin:auto\">");


   print($self->getParsedTemplate("tmpl/applcitransfer.".$mode.".header",
      {
         static  =>{
                  CAPPL=>$rec->{cappl},
                  EAPPL=>$rec->{eappl}
         }
      }
   ));
   #
   #
   #
   if ($mode eq "EApprove"){
      if ($rec->{eapplackdate} eq ""){
         print($self->getParsedTemplate("tmpl/applcitransfer.".$mode.".edit",
            {
               static  =>{
                        CAPPL=>$rec->{cappl},
                        EAPPL=>$rec->{eappl}
               }
            }
         ));
      }
      else{
         print($self->getParsedTemplate("tmpl/applcitransfer.".$mode.".show",
            {
               static  =>{
                        CAPPL=>$rec->{cappl},
                        EAPPL=>$rec->{eappl},
                        CAPPLACKUSER=>$rec->{capplackuser},
                        CAPPLACKDATE=>$rec->{capplackdate},
                        EAPPLACKUSER=>$rec->{eapplackuser},
                        EAPPLACKDATE=>$rec->{eapplackdate}
               }
            }
         ));
      }
   }
   if ($mode eq "CApprove"){
      if ($rec->{capplackdate} eq ""){
         print($self->getParsedTemplate("tmpl/applcitransfer.".$mode.".edit",
            {
               static  =>{
                        CAPPL=>$rec->{cappl},
                        EAPPL=>$rec->{eappl}
               }
            }
         ));
      }
      else{
         print($self->getParsedTemplate("tmpl/applcitransfer.".$mode.".show",
            {
               static  =>{
                        CAPPL=>$rec->{cappl},
                        EAPPL=>$rec->{eappl},
                        CAPPLACKUSER=>$rec->{capplackuser},
                        CAPPLACKDATE=>$rec->{capplackdate},
                        EAPPLACKUSER=>$rec->{eapplackuser},
                        EAPPLACKDATE=>$rec->{eapplackdate}
               }
            }
         ));
      }
   }
   ######################################################################

   printf("<br>\n");
   printf("<div style=\"border-style:solid;border-width:1px;".
          "overflow:auto;height:100px;padding-left:5px\">\n");
   printf("<xmp>%s</xmp>",$rec->{configitems});
   printf("</div>");
   printf("<br>\n");


   ######################################################################

   print($self->getParsedTemplate("tmpl/applcitransfer.signaturetext",
      {
         static  =>{
                  CAPPL=>$rec->{cappl},
                  RAPPL=>$rec->{cappl}
         }
      }
   ));


   printf("</div>");
   print $self->HtmlPersistentVariables("id","mode");
   print $self->HtmlBottom(body=>1,form=>1);
}





sub EApprove
{
   my $self=shift;

   my ($func,$p)=$self->extractFunctionPath();

   if ($p ne ""){
      $p=~s/[^0-9]//g;
      $self->HtmlGoto("../Approve",post=>{id=>$p,mode=>$func});
      return();
   }
   print $self->noAccess();
   return();
}


sub CApprove
{
   my $self=shift;

   my ($func,$p)=$self->extractFunctionPath();

   if ($p ne ""){
      $p=~s/[^0-9]//g;
      $self->HtmlGoto("../Approve",post=>{id=>$p,mode=>$func});
      return();
   }
   print $self->noAccess();
   return();
}









1;
