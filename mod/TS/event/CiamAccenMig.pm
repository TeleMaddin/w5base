package TS::event::CiamAccenMig;
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
@ISA=qw(kernel::Event);

my $trans;

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);

   return($self);
}


sub CiamAccenMig
{
   my $self=shift;

   my $user=getModuleObject($self->Config,"base::user");
   my $wf=getModuleObject($self->Config,"base::workflow");

   my @trans=split(/\n/,$trans);
   my @mig=map({
     my @map;
        if (my ($new,$old)=$_=~m/^\s*([0-9]+)\s+([0-9]+)\s*$/){
           $map[0]=$old;
           $map[1]=$new;
        }
        elsif (my ($old)=$_=~m/^\s*([0-9]+)\s*$/){
           $map[0]=$old;
           $map[1]=undef;
        }
     \@map;
   } @trans);

   my $c=0;
   foreach my $map (@mig){
      $user->ResetFilter();
      my $olddsid="tCID:".$map->[0];
      $user->SetFilter({dsid=>\$olddsid,cistatusid=>"<6"});
      my ($oldurec,$msg)=$user->getOnlyFirst(qw(ALL));
      if (defined($oldurec) && $map->[1] ne ""){
         $user->ResetFilter();
         my $newdsid="tCID:".$map->[1];
         $user->SetFilter({dsid=>\$newdsid,cistatusid=>"<6"});
         my ($newurec,$msg)=$user->getOnlyFirst(qw(ALL));
         if (defined($newurec)){
            $c++;
            printf STDERR ("Trans: %s\n".
                           "       -> %s\n\n",
                           $oldurec->{fullname},
                           $newurec->{fullname});
            if (my $id=$wf->ValidatedInsertRecord({
                  class    =>'base::workflow::ReplaceTool',
                  step     =>'base::workflow::ReplaceTool::approval',
                  name     =>'Accenture replace: '.$oldurec->{fullname},
                  stateid  =>2,
                  fwdtarget           => 'base::grp',
                  fwdtargetid         => '1',
                  replaceat           =>'ALL',
                  replaceoptype       => 'base::user',
                  replacesearchid       => $oldurec->{userid},
                  replacereplacewithid  => $newurec->{userid},
                  srcsys=>$self->Self
               })){
               printf STDERR ("Replace started at $id\n");
               if (1){
                  $user->ResetFilter();
                  $user->ValidatedUpdateRecord($oldurec,{cistatusid=>'6'},{
                     userid=>\$oldurec->{userid}
                  });
               }
            }
         }

        
      }
   }
   printf STDERR ("found %d mappings\n",$c);


#   printf STDERR ("fifi trans=%s\n",Dumper(\@mig));


   return({exitcode=>0});
}



$trans=<<EOF;
tCID  tCID alt
200106007   304318
200106009   1552187
200106011   48250774
200106013   607999
200106015   316005
200106017   304278
200106019   307698
200106021   313752
200106023   307730
200106025   302829
200106027   301635
200106029   345080
200106033   315796
200106035   79006590
200106037   316026
200106039   315814
200106041   79006844
200106043   288639
200118015   107474993
200118017   90931650
200118019   66953848
200118021   20787958
200118023   78389396
200118025   23674792
200118027   93880970
200118029   102921550
200118031   2163102
200118033   102688390
200121315   3373545
200121317   119790698
200121319   118850412
200121321   118850173
200121323   117827061
200121325   105938850
200121327   104356310
200121329   92939485
200121331   92939283
200121333   92937900
200121335   92936508
200121337   92554833
200121339   92454724
200121341   81587123
200121343   80248342
200121345   79147649
200121347   78243850
200121349   78100645
200121351   74332333
200121353   74208520
200121355   66155214
200121357   66154846
200121359   66154772
200121361   66154319
200121363   56692207
200121365   55831757
200121367   49963403
200121369   48936952
200121371   48250780
200121373   47151450
200121375   41141162
200121377   34637238
200121379   34636938
200121381   34636492
200121383   34635973
200121385   34635750
200121387   33353005
200121389   33352740
200121391   33352738
200121393   29675104
200121395   28758008
200121397   23942441
200121399   23037434
200121401   22003954
200121403   21189367
200121405   18613312
200121407   13870503
200121409   12509316
200121411   11949230
200121415   10836601
200121417   10200971
200121419   7608640
200121423   5682598
200121425   5682332
200121427   4383487
200121429   4372663
200121431   4261162
200121433   4260707
200121435   3959333
200121437   3916378
200121439   3914587
200121441   3894845
200121443   3882546
200121445   3866699
200121447   3847594
200121449   3837308
200121453   3806419
200121455   3801888
200121457   3790182
200121459   3787358
200121461   3722196
200121463   3481781
200121465   3481748
200121467   3481088
200121469   3473215
200121471   3466134
200121473   3396665
200121475   3385929
200121477   3370267
200121479   3369822
200121481   3165960
200121483   3015959
200121485   2507355
200121487   2485345
200121489   1539223
200121491   1538574
200121493   1538562
200121495   1538560
200121497   1538556
200121499   1528589
200121501   1528539
200121503   1528266
200121505   1527703
200121507   1524751
200121509   1464438
200121511   1317739
200121513   1288495
200121515   1258446
200121517   1258362
200121519   1241303
200121521   1234513
200121523   1225984
200121525   1213871
200121527   1179063
200121529   1176429
200121531   1174823
200121533   1167708
200121535   1166872
200121537   1165318
200121539   1164898
200121541   1163820
200121543   1163212
200121545   1161688
200121547   1158688
200121549   1158363
200121552   1157456
200121557   1156595
200121562   1156475
200121567   1154154
200121576   1153007
200121581   1150197
200121583   1149004
200121585   806150
200121587   784282
200121589   780122
200121591   770153
200121593   764168
200121595   759867
200121597   755864
200121601   741455
200121603   738781
200121605   733668
200121607   733305
200121609   733295
200121613   707553
200121615   699132
200121617   682084
200121619   676254
200121621   675431
200121623   669245
200121627   668922
200121629   662920
200121632   662763
200121637   644163
200121647   640350
200121652   638692
200121657   636978
200121662   633288
200121667   628476
200121672   628057
200121676   616500
200121684   608315
200121686   606882
200121688   606628
200121690   605534
200121692   605088
200121694   599258
200121696   595617
200121700   586546
200121702   583508
200121704   581258
200121706   579678
200121708   576251
200121710   575396
200121712   575310
200121714   565766
200121716   351281
200121718   350814
200121720   350813
200121722   350750
200121724   350615
200121726   344041
200121728   342218
200121730   342216
200121732   341892
200121734   340906
200121736   340089
200121738   337133
200121740   337103
200121742   336878
200121744   336683
200121746   336540
200121750   336418
200121752   336051
200121754   334757
200121756   334665
200121758   332922
200121760   331262
200121765   329857
200121770   329839
200121785   327479
200121794   325426
200121803   323961
200121808   323550
200121813   323497
200121815   323490
200121817   322257
200121819   322236
200121821   322231
200121823   322230
200121825   322229
200121827   322037
200121829   321997
200121831   320465
200121833   319786
200121835   318022
200121837   318021
200121839   317517
200121841   317133
200121843   317029
200121845   316378
200121847   316357
200121849   316337
200121851   316232
200121853   316138
200121855   316137
200121857   316027
200121859   316017
200121861   316015
200121863   316012
200121865   316004
200121867   315997
200121869   315990
200121871   315988
200121873   315984
200121875   315978
200121877   315942
200121879   315890
200121881   315875
200121883   315849
200121885   315848
200121887   315846
200121889   315844
200121891   315838
200121893   315832
200121895   315827
200121897   315824
200121899   315811
200121901   315809
200121903   315806
200121905   315782
200121907   315765
200121909   315717
200121911   315545
200121913   314899
200121915   312495
200121917   311551
200121919   311517
200121921   309082
200121923   309024
200121925   309018
200121927   308998
200121929   308995
200121931   308553
200121933   308426
200121935   308066
200121938   308049
200121942   307769
200121947   307727
200121952   307616
200121957   307596
200121962   307486
200121967   307189
200121972   307182
200121977   307163
200121982   307031
200121987   307014
200121992   306993
200121994   306981
200121996   306853
200121998   306648
200122000   306576
200122002   306556
200122004   306498
200122006   306372
200122008   306313
200122010   306293
200122012   306276
200122014   306252
200122016   305752
200122018   305477
200122020   305450
200122022   305237
200122024   305010
200122026   304955
200122028   304744
200122030   304743
200122032   304709
200122034   304442
200122036   304325
200122038   304197
200122040   304196
200122042   304189
200122044   303660
200122046   303597
200122048   303505
200122050   303470
200122052   303469
200122054   303306
200122056   303303
200122058   303170
200122060   303139
200122062   303111
200122064   303093
200122066   303075
200122068   303071
200122070   303048
200122072   302944
200122074   302875
200122076   302791
200122078   302731
200122080   302713
200122082   302707
200122084   302679
200122086   302671
200122088   302622
200122090   302610
200122092   302551
200122094   302544
200122096   302519
200122098   302494
200122100   302454
200122104   302403
200122106   302385
200122108   302349
200122110   302329
200122112   302213
200122114   302155
200122116   302115
200122118   302050
200122120   302025
200122122   301971
200122124   301963
200122128   301946
200122133   301885
200122138   301831
200122142   301825
200122147   301800
200122152   301794
200122157   301788
200122162   301744
200122167   301686
200122172   301666
200122176   301627
200122179   301589
200122181   301557
200122183   301545
200122185   301482
200122187   301447
200122189   301329
200122191   301316
200122193   301276
200122197   301180
200122199   301145
200122201   301035
200122203   300875
200122205   300845
200122207   300773
200122209   300753
200122211   300739
200122213   300738
200122215   300689
200122217   300670
200122219   300669
200122221   300289
200122223   299038
200122225   298739
200122227   298559
200122229   298244
200122231   297886
200122233   294606
200122235   294503
200122237   294476
200122239   294427
200122241   294425
200122243   294379
200122245   294360
200122247   294359
200122249   294338
200122251   294094
200122253   293770
200122255   293691
200122257   293352
200122259   292574
200122261   292565
200122263   292501
200122265   292375
200122267   292145
200122269   291847
200122271   291841
200122273   291139
200122275   290874
200122277   290725
200122279   290509
200122281   290394
200122283   289932
200122285   289762
200122287   289497
200122289   289412
200122291   289078
200122293   302859
200122295   288910
200122297   288824
200122299   288461
200122301   288443
200122303   288425
200122346   288154
200122348   288067
200122350   287929
200122352   287486
200122354   286709
200122356   286668
200122359   286659
200122364   286571
200122369   286333
200122374   285748
200128525   20751069
200128530   108269574
200128535   114037260
200128540   62950436
200128543   51689501
200128545   73652827
200128547   23257388
200128549   59236146
200128886   35548724
200128945   103806561
200128947   113011383
200128949   58821622
200128951   45063280
200128953   83143397
200128955   69164112
200128957   41624379
200128959   200013765
200128961   114948686
200128963   85997391
200128965   118601370
200128967   67793769
200128969   81926383
200128971   50783467
200128973   75370473
200128975   106273935
200129922   200008822
200129924   119680287
200129926   119465791
200129928   118063954
200129930   114957198
200129932   106744060
200129934   101658192
200129936   90231017
200129938   87369062
200129940   86702084
200129942   73965057
200129944   70623571
200129946   70584849
200129948   70507599
200129950   67102030
200129952   64500320
200129954   64233467
200129956   63442225
200129958   55831547
200129960   54867746
200129962   53161395
200129964   51895157
200129966   51783687
200129968   47919754
200129970   44061051
200129972   40194571
200129974   36731454
200129976   35921135
200129978   33712692
200129980   31687935
200129982   30585493
200129984   30229028
200129986   28673485
200129988   28365714
200129990   27700444
200129992   27434792
200129994   23161397
200129996   12673074
200129998   11338375
200130000   11335017
200130002   11332100
200130004   11325990
200130006   11317272
200130008   11307140
200130010   11297033
200130012   11296725
200130014   11258901
200130016   2391669
200130018   1315574
200130020   352637
200130022   344851
200130886   200085078
200130888   200085073
200130890   118600901
200130892   118526494
200130894   109593617
200130896   106686419
200130898   106281766
200130900   97435529
200130902   94740279
200130904   93646481
200130906   93279016
200130908   86831586
200130910   86155089
200130912   84567404
200130914   77482691
200130916   68013430
200130918   68013425
200130920   67180778
200130922   64500329
200130924   63410664
200130926   63192399
200130928   58954978
200130930   44061336
200130932   40836742
200130934   38730140
200130936   34840456
200130938   23161391
200130940   20777841
200130942   3244487
200130944   2422305
200130946   1434638
200132520   200083729
200132522   200072377
200132524   118771830
200132526   118405652
200132528   115566989
200132530   109980067
200132532   105223915
200132534   105223893
200132536   102077393
200132538   94633170
200132540   92832911
200132542   92289762
200132544   85979297
200132546   85894462
200132548   84605906
200132550   80740483
200132552   78010405
200132554   74591507
200132556   70490539
200132558   69865289
200132560   69841271
200132562   66163694
200132564   64574072
200132566   60194613
200132568   57039272
200132570   51775946
200132572   48512557
200132574   47320763
200132576   46236494
200132578   44746149
200132580   40437185
200132582   38730248
200132584   36672734
200132586   18489239
200132588   11307847
200133357   200091690
200133359   118771809
200133361   118001115
200133363   115566995
200133365   115566993
200133367   115249714
200133369   112789491
200133371   112568059
200133373   110144140
200133375   100165935
200133377   96318696
200133379   89758253
200133381   89318110
200133383   87203873
200133385   86397592
200133387   77504418
200133389   71733223
200133391   71602316
200133393   70494548
200133395   69863057
200133397   67670513
200133399   64078934
200133401   63310442
200133403   55831289
200133405   47919801
200133407   33598914
200133409   29443305
200133411   21164203
200133413   12666696
200133415   11343666
200133417   8973118
200133419   2655227
200133421   344667
200134813   200092483
200134815   200010135
200134817   118771821
200134819   112789505
200134821   112789501
200134823   111281044
200134825   106493774
200134827   106253904
200134829   106253898
200134831   104645972
200134833   93346818
200134835   92575957
200134837   91514798
200134839   87191055
200134841   86686351
200134843   86078722
200134845   78209287
200134847   77933919
200134849   77504408
200134851   77374308
200134853   72849760
200134855   70232963
200134857   69863035
200134859   69863031
200134861   69142309
200134863   67636745
200134865   63442198
200134867   63192543
200134869   44746165
200134871   44433388
200134873   44061688
200134875   41317198
200134877   39235159
200134879   34796678
200134881   34406392
200134883   31324545
200134885   29848500
200134887   29848487
200134889   28841558
200134891   27434329
200134893   22510612
200134895   22122029
200134897   14139769
200134899   10036677
200134901   3372643
200134903   1241562
200135248   58994100
200135250   58262028
200135252   55213888
200135254   50783471
200135256   46236380
200135258   34796682
200135260   19368619
200135262   343607
200135264   200090737
200135266   119275712
200135268   118771815
200135270   118421313
200135272   116818918
200135274   115473528
200135276   115218879
200135278   114535952
200135280   113528981
200135282   110108097
200135284   94583832
200135286   93875333
200135288   89758245
200135290   80470777
200135292   80453382
200135294   78614230
200135296   78414919
200135298   78358110
200135300   73974963
200135302   73652821
200135304   72850141
200135306   72850135
200135308   70964050
200135310   64637646
200135312   60194611
200136576   22149445
200136578   20439643
200136580   12670027
200136582   11345070
200136584   2163113
200136586   1425800
200136588   200088291
200136590   200033628
200136592   200031092
200136594   200012417
200136596   119467420
200136598   114992554
200136600   112789495
200136602   110835211
200136604   97216924
200136606   93896066
200136608   93151957
200136610   73652842
200136612   72999248
200136614   70509296
200136616   68398189
200136618   67776106
200136620   66930233
200136622   65630291
200136624   65176896
200136626   64285955
200136628   59928516
200136630   59236268
200136632   54078038
200136634   48509117
200136636   34796665
200136638   34406424
200136640   34406414
200136642   30501293
200136644   22339860
200137403   200092481
200137405   200075533
200137407   119893259
200137409   116102122
200137411   115566991
200137413   112789503
200137415   93309603
200137417   85893585
200137419   83143399
200137421   70711857
200137423   70258013
200137425   62583064
200137427   59241629
200137429   42983985
200137431   39235044
200137433   35668863
200137435   30066264
200137437   11309689
200137439   8907295
   1426967
   1526224
   11309779
   12667071
   20750982
   22339884
   31324548
   34406295
   43183088
   43581992
   48424235
   51583467
   56676189
   64304395
   64843787
   70834502
   76920509
   76978329
   80173459
   81926127
   85954373
   85954375
   87191059
   89327925
   89657438
   92289798
   104492159
   112789493
   113599509
   117548055
   119980616
   200016325
   200130372
EOF


1;
