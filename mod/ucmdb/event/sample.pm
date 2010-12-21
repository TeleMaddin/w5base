package ucmdb::event::sample;
#  W5Base Framework
#  Copyright (C) 2006  Hartmut Vogler (it@guru.de)
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
#use SOAP::Lite +trace=>'all';
use SOAP::Lite;
@ISA=qw(kernel::Event);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);

   return($self);
}

sub Init
{
   my $self=shift;


   $self->RegisterEvent("ucmdbSample",
                        "ucmdbSample",timeout=>30);
   return(1);
}

sub ucmdbSample
{
   my $self=shift;
   my %param=@_;

#   my $wsuser=$self->Config->Param("WEBSERVICEUSER");
#   my $wspass=$self->Config->Param("WEBSERVICEPASS");
#   my $wsproxy=$self->Config->Param("WEBSERVICEPROXY");
#   $wsuser=$wsuser->{ucmdb} if (ref($wsuser) eq "HASH");
#   $wspass=$wspass->{ucmdb} if (ref($wspass) eq "HASH");
#   $wsproxy=$wsproxy->{ucmdb} if (ref($wsproxy) eq "HASH");
#
#   if ($wsuser eq ""){
#      return({exitcode=>0,msg=>'ok - no web service account data'});
#   }
#   eval('
#   sub SOAP::Transport::HTTP::Client::get_basic_credentials { 
#       return $wsuser => $wspass;
#   }
#   ');
#
#   my $inetwxmltyp="http://schemas.hp.com/ucmdb/1/types";
#   my $inetwxmlclas="http://schemas.hp.com/ucmdb/1/params/classmodel";
#
#   my $method = SOAP::Data->name('getCmdbClassDefinition')->prefix('clas');
#
#   my @appl;
#   push(@appl,SOAP::Data->name("callerApplication")
#        ->type("")->prefix('typ')->value("w5base"));
#   my @SOAPparam;
#   push(@SOAPparam,SOAP::Data->name("cmdbContext")
#        ->type("")->prefix('clas')->value(\@appl));
#   push(@SOAPparam,SOAP::Data->name("className")
#        ->type("")->prefix('clas')->value("nt"));
#
#   my ($result,$fault)=$this->getAllClassesHierarchy();
#
#   my $soap=SOAP::Lite->uri($inetwxmlclas)->proxy($wsproxy)
#                      ->on_action(sub{$_[1]});
#   $soap->serializer->register_ns($inetwxmltyp,'typ');
#   $soap->serializer->register_ns($inetwxmlclas,'clas');
#
#   my $res;
#   eval('$res=$soap->call($method=>@SOAPparam);'); 
#   if (!defined($res) || ($@=~m/Connection refused/)){
#      msg(ERROR,"can not connect to ".$wsproxy);
#      return({exitcode=>10,
#              msg=>'can not connect to uCMDB - Connection refused'});
#   }
#
#   if ($res->fault){
#      $self->Log(ERROR,"trigger","uCMDB: ".$res->fault->{faultstring});
#      return({exitcode=>2,msg=>$res->fault->{faultstring}});
#   }
#   my $indata=$res->result();

   my ($result,$fault)=$self->getAllClassesHierarchy();

   if (defined($result)){
      print Dumper($result);
   }

   return({exitcode=>0,msg=>"ok"});
}

sub getAllClassesHierarchy
{
   my $self=shift;

   my @appl;
   push(@appl,SOAP::Data->name("callerApplication")
        ->type("")->prefix('typ')->value("w5base"));
   my @SOAPparam;
   push(@SOAPparam,SOAP::Data->name("cmdbContext")
        ->type("")->prefix('clas')->value(\@appl));

   my $soapresult=$self->ucmdbSoapOperation("getAllClassesHierarchy",\@SOAPparam);

   if (defined($soapresult)){
      my @l;
      foreach my $rec (@{$soapresult->result()->{classHierarchyNode}}){
         push(@l,{id=>$rec->{'classNames'}->{'className'},
                  fullname=>$rec->{'classNames'}->{'displayName'},
                  parent=>$rec->{'classParentName'}});
      }
      return(\@l);
   }
   return(undef,"invalid result");


   return($soapresult->result());
}


sub ucmdbSoapOperation
{
   my $self=shift;
   my $SOAPmethod=shift;
   my $SOAPparam=shift;

   my $inetwxmltyp="http://schemas.hp.com/ucmdb/1/types";
   my $inetwxmlclas="http://schemas.hp.com/ucmdb/1/params/classmodel";

   my $wsuser=$self->Config->Param("WEBSERVICEUSER");
   my $wspass=$self->Config->Param("WEBSERVICEPASS");
   my $wsproxy=$self->Config->Param("WEBSERVICEPROXY");
   $wsuser=$wsuser->{ucmdb} if (ref($wsuser) eq "HASH");
   $wspass=$wspass->{ucmdb} if (ref($wspass) eq "HASH");
   $wsproxy=$wsproxy->{ucmdb} if (ref($wsproxy) eq "HASH");

   my $soap=SOAP::Lite->uri($inetwxmlclas)->proxy($wsproxy)
                      ->on_action(sub{$_[1]});
   $soap->serializer->register_ns($inetwxmltyp,'typ');
   $soap->serializer->register_ns($inetwxmlclas,'clas');

   my $method = SOAP::Data->name($SOAPmethod)->prefix('clas');

   eval('sub SOAP::Transport::HTTP::Client::get_basic_credentials { 
       return $wsuser => $wspass;
   }');

   my $res;
   eval('$res=$soap->call($method=>@$SOAPparam);'); 
   if (!defined($res) || ($@=~m/Connection refused/)){
      die("can not connect to ".$wsproxy);
   }
   return($res);
}







1;
