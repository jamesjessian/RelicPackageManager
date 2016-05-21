# Relic Package Manager
Basic Package Manager for IBM i, tested on:

+ 7.1
+ 7.2
+ 7.3

Currently, it **only supports GitHub**. This is because my hosted system doesn't have a version of Git, once my request has gone through to get it installed, you'll be able to use any Git repo.

#### How to install

The current way of installing

1. You'll need to get the source from this repo into a source member or IFS file - FTP / Copy+Paste via Rational Developer for i. I've been using `FFPKGMGR` as my development library, but the choice is your.
2. `CRTSQLRPGI OBJ(FFPKGMGR/RELIC) SRCFILE(FFPKGMGR/QRPGLESRC) SRCMBR(RELIC) COMMIT(*NONE) OPTION(*EVENTF) RPGPPOPT(*LVL2) REPLACE(*YES) DBGVIEW(*SOURCE)` to compile.
3. Should hopefully be installed. 

**OR**

1. Do a `git clone https://github.com/Club-Seiden/RelicPackageManager.git /home/[USER]/Relic/` where `[USER]` is your user profile name (you also have to create the Relic directory). 
2. Compile RELIC.RPGLE from the IFS (I use FFPKGMGR, you can use any) using `CRTSQLRPGI` with `COMMIT(*NONE)`.

#### How to use

1. Find a GitHub repo you want to install onto your system, for example [FFEDIT](https://github.com/RelicPackages/FFEDIT).
2. There are three paramters to the RELIC program. The organisation or user the repo is in, the repo name and what library to use/install into. Run `CALl RELIC PARM('RelicPackages' 'FFEDIT' 'SOMELIB')` for FFEDIT to be installed into SOMELIB.

#### How to create a build file.

1. Create a `build.txt` file in your repo.
2. A build file contains 3 sections. `dirs:`, `files:` and `build:`. `dirs:` is the list of directories and sub-directories to be made. `files:` is the list of sources/files to download onto your system. `build:` is the commands to run after all directories and sources have been made.

You can find examples in any repo in the [RelicPackages organisation](https://github.com/RelicPackages).
