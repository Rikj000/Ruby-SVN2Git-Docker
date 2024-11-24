# Ruby SVN2Git Docker

<p align="left">
    <a href="https://github.com/Rikj000/Ruby-SVN2Git-Docker/blob/development/LICENSE">
        <img src="https://img.shields.io/github/license/Rikj000/Ruby-SVN2Git-Docker?label=License&logo=gnu" alt="GNU General Public License">
    </a> <a href="https://github.com/Rikj000/Ruby-SVN2Git-Docker/releases">
        <img src="https://img.shields.io/github/downloads/Rikj000/Ruby-SVN2Git-Docker/total?label=Total%20Downloads&logo=github" alt="Total Releases Downloaded from GitHub">
    </a> <a href="https://github.com/Rikj000/Ruby-SVN2Git-Docker/releases/latest">
        <img src="https://img.shields.io/github/v/release/Rikj000/Ruby-SVN2Git-Docker?include_prereleases&label=Latest%20Release&logo=github" alt="Latest Official Release on GitHub">
    </a> <a href="https://www.iconomi.com/register?ref=zQQPK">
        <img src="https://img.shields.io/badge/ICONOMI-Join-blue?logo=bitcoin&logoColor=white" alt="ICONOMI - The world’s largest crypto strategy provider">
    </a> <a href="https://www.buymeacoffee.com/Rikj000">
        <img src="https://img.shields.io/badge/-Buy%20me%20a%20Coffee!-FFDD00?logo=buy-me-a-coffee&logoColor=black" alt="Buy me a Coffee as a way to sponsor this project!"> 
    </a>
</p>

Simple `Dockerfile` to run the Ruby [Nirvdrum/SVN2Git](https://github.com/nirvdrum/svn2git) script under a [Docker](https://www.docker.com/) container!

## Reasoning
- [Nirvdrum/SVN2Git](https://github.com/nirvdrum/svn2git) works better then my own [Rikj000/SVN-to-Git-convert](https://github.com/Rikj000/SVN-to-Git-convert) tool,   
    which I will archive in favor of this container.
- [Nirvdrum/SVN2Git](https://github.com/nirvdrum/svn2git) requires a very old version of Git (`v1.8.3.1`) to successfully convert branches + tags,   
    which is not shipped by Linux distributions anymore, so this container builds it from source.   
    See: https://github.com/nirvdrum/svn2git/blob/v2.4.0/lib/svn2git/migration.rb#L353
- [Nirvdrum/SVN2Git](https://github.com/nirvdrum/svn2git) is not actively maintained anymore,   
    which leads to unresolved bugs in the official version, which this container seeks to patch out.

    **Current patches:**
    - [Patch Svn2Git v2.4.0 to support Ruby v3.2+](https://github.com/nirvdrum/svn2git/pull/333)
    - [Patch Svn2Git v2.4.0 to not error on `$stdin.gets.chomp`](https://github.com/nirvdrum/svn2git/pull/308)

## Dependencies
- [bash](https://archlinux.org/packages/core/x86_64/bash/)
- [coreutils](https://archlinux.org/packages/core/x86_64/coreutils/)
- [curl](https://archlinux.org/packages/core/x86_64/curl/)
- [gawk](https://archlinux.org/packages/core/x86_64/gawk/)
- [sed](https://archlinux.org/packages/core/x86_64/sed/)
- [wget](https://archlinux.org/packages/extra/x86_64/wget/)
- [jq](https://archlinux.org/packages/extra/x86_64/jq/)
- [docker](https://archlinux.org/packages/extra/x86_64/docker/)
- [subversion](https://archlinux.org/packages/extra/x86_64/subversion/)

## Installation
1. Download the latest `Dockerfile` from the `Ruby-SVN2Git-Docker` releases
```bash
wget "$(
    curl -s -H "Accept: application/vnd.github.v3+json" \
    'https://api.github.com/repos/Rikj000/Ruby-SVN2Git-Docker/releases/latest' \
    | jq .assets[0].browser_download_url | sed -e 's/^"//' -e 's/"$//')";
```

2. Build svn2git container
```bash
docker build . -t svn2git:v2.4.0;
```

## Usage

1. Check out the SVN repository at the latest revision
```bash
svn checkout \
    "file:///path/to/svn/input/repo/@HEAD" \
    "/path/to/svn/output/checkout/";
```

2. Query SVN checkout version history for 'authors-file.txt'
```bash
cd "/path/to/svn/output/checkout/";
svn log -q | \
    awk -F '|' '/^r/ {gsub(/ /, "", $2); sub(" $", "", $2); print $2" = "$2" <"$2">"}' | \
    sort -u > "/path/to/authors-file.txt";
```

3. Run svn2git container example
```bash
mkdir "/path/to/git/output/repo/";
docker run \
--volume "/path/to/git/output/repo:/var/svn2git" \
--volume "/path/to/svn/input/repo:/var/svn" \
--volume "/path/to/authors-file.txt:/var/authors-file.txt" \
    svn2git:v2.4.0 \
    "file:///var/svn" \
    --trunk "trunk_dir" \
    --branches "branches_dir" \
    --tags "tags_dir" \
    --authors "/var/authors-file.txt";
```

**Note** `--rootistrunk` is broken, instead use `--trunk "/" --nobranches --notags`    
See: https://github.com/nirvdrum/svn2git/issues/127

**Note** `--exclude` is broken

4. Push all branches + tags to Forgejo (or another Git forge like Github/Gitlab)
```bash
cd "/path/to/git/output/repo/";
git remote add origin http://localhost:3000/username/projectname;
git push origin '*:*';
```
