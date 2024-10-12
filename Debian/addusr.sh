#!/usr/bin/bash
#############################################################################
#
# 1. create user and build home directory
# 2. if assign $2,then user added $2 group if $2 group is exist,if not assign,
#    then group name as same as user
# 3. the home directory is set 700
# 4. append bash_profile to new user
# 
#############################################################################
create_user()
{
num=` grep $1 /etc/passwd|wc -l `

if [ $num -ge 1 ]
then
    echo "the "$1" user is exist."
    exit 1
fi

if [ -z $2 ]
then
    useradd -d /home/$1 -s /bin/bash -m -U $1
else
    groupnum=` grep $2 /etc/group|wc -l `
    if [ $groupnum -eq 0 ]
    then
        echo "the group "$2" is not exist"
        exit 1
    fi
    useradd -d /home/$1 -g $2 -s /bin/bash -m $1
fi
chmod 700 /home/$1
}

add_profile()
{
echo "# .bash_profile

# Get the aliases and functions
if [ -f ~/.bashrc ]; then
        . ~/.bashrc
fi

PATH=\$PATH:\$HOME/bin:\$HOME/shell:.
export PATH

LD_LIBRARY_PATH=\$HOME/lib
export  LD_LIBRARY_PATH

alias l='ls -l'
set -o vi
" >>/home/$1/.bash_profile

if [ -z $2 ]
then
    chown $1:$1 /home/$1/.bash_profile
else
    chown $1:$2 /home/$1/.bash_profile
fi
}

if [ $# -eq 0 ]
then
    echo "usage: adduser.sh username [groupname]"
    exit 1
fi

create_user $1 $2
add_profile $1 $2
