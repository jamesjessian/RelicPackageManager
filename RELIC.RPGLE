
       // Relic is an open-source package manager created by Liam Allan.
       // It may also go by these names:
       //   - Relic Package Manager
       //   - DWNPKG

       Ctl-Opt DftActGrp(*No) ActGrp(*NEW);

       dcl-pr Cmd int(10) extproc('system');
         cmdstring pointer value options(*string);
       end-pr;
       Dcl-s errmsgid char(7) import('_EXCP_MSGID');

       Dcl-Pr printf Int(10) ExtProc('printf');
         format Pointer Value Options(*String);
       END-PR;

       //*********************************************

       dcl-pr OpenFile pointer extproc('_C_IFS_fopen');
         *n pointer value;  //File name
         *n pointer value;  //File mode
       end-pr;

       dcl-pr ReadFile pointer extproc('_C_IFS_fgets');
         *n pointer value;  //Retrieved data
         *n int(10) value;  //Data size
         *n pointer value;  //Misc pointer
       end-pr;

       dcl-pr CloseFile extproc('_C_IFS_fclose');
         *n pointer value;  //Misc pointer
       end-pr;

       dcl-s PathFile char(50) ;
       dcl-s OpenMode char(5) ;
       dcl-s FilePtr pointer inz ;
       dcl-s RtvData char(256) ;

       //*********************************************

       Dcl-S gUser     Char(10)     Inz(*User);

       Dcl-S REPOLINK  Varchar(128); //Ending with /
       Dcl-S IFSLINK   Varchar(128); //Ending with /
       Dcl-s INTOLIB   Char(10);

       Dcl-S gMode  Char(10);
       Dcl-S gIndex Int(5);

       Dcl-S gFiles Char(60)  Dim(50);
       Dcl-S gDirs  Char(20)  Dim(15);
       Dcl-S gCmds  Char(200) Dim(100);

       Dcl-S gFails Int(3);

       //*********************************************

       Dcl-Pi RELIC;
         pGHUser Char(20) Const;
         pGHRepo Char(20) Const;
         pLib    Char(10) Const;
       END-PI;

       If (%Parms < 3 OR %Parms > 4);
         Print('Three parameters required.');
         Return;
       ENDIF;

       //*********************************************

       REPOLINK = 'https://raw.githubusercontent.com'
                + '/' + %Trim(pGHUser)
                + '/' + %Trim(pGHRepo)
                + '/master/';

       INTOLIB  = pLib;
       IFSLINK  = '/home/' + %Trim(gUser)
                + '/' + %Trim(pGHRepo) + '/';

       gFails   = 0;

       IFS_CreateDir(IFSLINK);

       If (BUILD_Download());
         BUILD_Process();

         If (gFails = 0);
           Print('Built ' + %Trim(pGHRepo) + ' sucessfully.');
           Cmd('RMDIR DIR(''' + IFSLINK + ''') SUBTREE(*ALL)');
         Else;
           Print('Failed to build ' + %Trim(pGHRepo)
               + ', error count: ' + %Char(gFails));
         ENDIF;
       Endif;

       *InLR = *On;
       Return;

       //*********************************************

       Dcl-Proc Print;
         Dcl-Pi Print;
           pValue Char(80) Const;
         END-PI;

         printf(%Trim(pValue) + x'25');
       End-Proc;

       //*********************************************

       Dcl-Proc IFS_CreateDir;
         Dcl-Pi *N;
           pDir Varchar(128) Const;
         END-PI;

         If (Cmd('MKDIR DIR(''' + %Trim(pDir) + ''')') = 1);
           Print('Failed to make directory "' + %Trim(pDir) + '".');
         Endif;
       End-Proc;

       //*********************************************

       Dcl-Proc FILE_Download;
         Dcl-Pi *N;
           pFile Varchar(60) Const; //name.ext
         END-PI;

         Dcl-S lLoc  Varchar(128);
         Dcl-S lFile SQLTYPE(BLOB_FILE);

         lLoc = REPOLINK + pFile;
         lFile_Name = IFSLINK + pFile;
         lFile_NL   = %Len(%TrimR(lFile_Name));
         lFile_FO   = SQFOVR;

         Exec SQL
           SELECT SYSTOOLS.HTTPGETBLOB(:lLoc, '') lFile_DATA
           INTO :lFile
           FROM SYSIBM.SYSDUMMY1;

         //00819

         If (Cmd('CHGATR '
             + 'OBJ(''' +  %Trim(lFile_Name) + ''') '
             + 'ATR(*CCSID) VALUE(00819)') = 1);

             Print('Failed to change CCSID of "' + %Trim(pFile) + '".');
         ENDIf;

       END-PROC;

       //*********************************************

       Dcl-Proc BUILD_Download;
         Dcl-Pi *N Ind End-Pi;

         FILE_Download('build.txt');
         PathFile = IFSLINK + 'build.txt' + x'00';
         OpenMode = 'r' + x'00';
         FilePtr  = OpenFile(%addr(PathFile):%addr(OpenMode));

         If (FilePtr = *null);
           Print('Failed to read build file.');
           Return *Off;
         EndIf;

         dow  (ReadFile(%addr(RtvData):32767:FilePtr) <> *null) ;
           RtvData = %xlate(x'00':' ':RtvData) ;  //End of record null
           RtvData = %xlate(x'25':' ':RtvData) ;  //Line feed (LF)
           RtvData = %xlate(x'0D':' ':RtvData) ;  //Carriage return (CR)
           RtvData = %xlate(x'05':' ':RtvData) ;  //Tab
           RtvData = %Trim(RtvData);

           If (RtvData = *Blank);
             Iter;
           ENDIF;

           Select;

             When (RtvData = 'dirs:');
               gMode  = '*DIRS';
               gIndex = 1;

             When (RtvData = 'files:');
               gMode  = '*FILES';
               gIndex = 1;

             When (RtvData = 'build:');
               gMode = '*BUILD';
               gIndex = 1;

             Other;
               Select;

                 When (gMode = '*DIRS');
                   gDirs(gIndex) = RtvData;
                   Print('Directory found: ' + RtvData);

                 When (gMode = '*FILES');
                   gFiles(gIndex) = RtvData;
                   Print('File found: ' + RtvData);

                 When (gMode = '*BUILD');
                   gCmds(gIndex) = RtvData;

               ENDSL;
               gIndex += 1;

           ENDSL;

           RtvData = ' ';
         enddo;

         Return *On;
       End-Proc;

       //*********************************************

       Dcl-Proc BUILD_Command;
         Dcl-Pi *N;
           pCmd Char(200) Value;
         END-PI;

         pCmd = %ScanRpl('&INTOLIB':%Trim(INTOLIB):pCmd);
         pCmd = %ScanRpl('&DIR/':%Trim(IFSLINK):pCmd);

         Monitor;
           If (Cmd(pCmd) = 1);
             gFails += 1;
             Print(%Subst(pCmd:1:52) + ' ...');
             Print('> ' + errmsgid);
             Print(*Blank);
           ENDIF;
         On-Error *All;
           gFails += 1;
           Print(%Subst(pCmd:1:52) + ' ...');
           Print('> Caused program crash');
           Print(*Blank);
         Endmon;
       END-PROC;

       //*********************************************

       Dcl-Proc BUILD_Process;

         Dcl-S lIndex Int(5) Inz(1);

         For lIndex = 1 to %Lookup(*Blank:gDirs)-1;
           IFS_CreateDir(IFSLINK + gDirs(lIndex));
         ENDFOR;

         For lIndex = 1 to %Lookup(*Blank:gFiles)-1;
           FILE_Download(gFiles(lIndex));
         ENDFOR;

         For lIndex = 1 to %Lookup(*Blank:gCmds)-1;
           BUILD_Command(gCmds(lIndex));
         ENDFOR;

       END-PROC; 
