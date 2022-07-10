# exports
export AWS_PAGER=""
export CONTAINER_NAME=bastion-ssh
export EDITOR=vim
export GIT_EDITOR=/usr/bin/vim
export GIT_PAGER=cat
export HOSTNAME=$CONTAINER_NAME
export LC_ALL=en_US.utf-8
export LANG=en_US.utf-8
export LC_CTYPE=utf-8
export PATH="${PATH}:${HOME}/.krew/bin"
export TERM=xterm-256color
export TILLER_NAMESPACE=tiller
export UPDATE_ZSH_DAYS=30
export ZSH_THEME=inspiration
export ZSH=~/.oh-my-zsh
export ZSHZ_CMD='j'

# env, not exported
SSH_ENV=$HOME/.ssh/environment
CASE_SENSITIVE="true"
DISABLE_CORRECTION="true"

# zsh plugins
plugins=(git colorize pip python zsh-z)

# load oh-my-zsh
source $ZSH/oh-my-zsh.sh

# aliases
alias j=zshz 2>&1
alias k=kubectl
alias listext='find . -not -iwholename "*.git*" -type f | egrep -i -E -o "\.{1}\w*$" | sort | uniq -c | sort -rn'
alias listlarge='find . -xdev -not -iwholename "*git*" -type f -size +100k -exec ls -lh {} \;'
alias listupperext='find . -xdev -not -iwholename "*.git*" -type f | egrep -o -E "\.{1}\b[A-Z]\w*\b$" | sort | uniq -c'
alias ls='exa -la'
alias md=mkdir
alias prettyjson='python -m json.tool'
alias tree="exa -T"
alias clip='xclip'
alias kgp='kubectl get pod'
alias kgs='kubectl get service'
alias kgt='kubectl get secret'

function kg() {
  local svc=$1
  local greptext=$2

  if [ "$#" -ne 2 ]; then
    echo "kube-get usage: kg k8-apiobject searchtext"
  else
    obj=$(kubectl get $svc | grep "$greptext" | head -n 1 |  cut -f1 -d ' ')
    ret=$?
    if [[ $ret -ne 0 ]]; then
      echo "$svc with pattern '$greptext' not found."
    else
      echo "$obj copied to clipboard."
      printf $obj | clip
    fi
  fi
}

# shell functions
function dpod() {
  export pod=$(k get po | grep $1 | cut -f1 -d ' ' | head -n 1)
  echo $pod
  kubectl describe pod $pod
}

function epod() {
  export pod=$(k get po | grep $1 | cut -f1 -d ' ' | head -n 1)
  echo $pod
  kubectl exec -it $pod -- sh
}

function findext() {
    str='*.'
    str2=$str$1
    find . -type f -not -iwholename "*.git*" -name "$str2" -exec ls -lh {} \;
}

function fex1 () {
    str='*.'
    str2=$str$1
    vim "`find . -type f -not -iwholename "*.git*" -name "$str2" -print | sed '1!d;q'`"
}

function display_ignore(){
  if [ -d "testignore" ]; then
    rm -rf testignore
  fi
  mkdir testignore
  find . -not -iwholename "*.git*" -type f | egrep -i -E -o "\.{1}\w*$" | sort | uniq > extlist.txt
  while IFS='' read -r line || [[ -n "$line" ]]; do
    touch ./testignore/f$line
  done < extlist.txt
  cd testignore
  /bin/ls | git check-ignore --stdin -n --verbose
  cd ..
  rm -rf ./testignore
}

function git-checkout-pr()
{
  if ! git config -l | grep -q "remote.origin.fetch=+refs/pull-requests/\*:refs/remotes/origin/pr/\*"; then
    git config --add remote.origin.fetch +refs/pull-requests/*:refs/remotes/origin/pr/*
  fi

  git fetch --prune
  git checkout pr/$1/merge
}

function tmx {
    readonly SESSIONNAME=${1:?"The session must be specified."}
    tmux has-session -t $SESSIONNAME &> /dev/null
    if [ $? != 0 ]
    then
        tmux new-session -s $SESSIONNAME -n script -d 
        #tmux send-keys -t $SESSIONNAME "cd ~/git" C-m
    fi
    tmux attach -t $SESSIONNAME
}

function start_agent {
    echo "Initializing new SSH agent..."
    cd ~/.ssh
    eval `/usr/bin/ssh-agent -s` && sleep 2
    echo succeeded
    chmod 600 "${SSH_ENV}"
    ssh-add id_rsa
    cd $OLDPWD
}

# start the ssh agent
if [ -f "${SSH_ENV}" ]; then
     . "${SSH_ENV}" > /dev/null
     ps -ef | grep ${SSH_AGENT_PID} | grep ssh-agent$ > /dev/null || {
        start_agent;
    }
else
    start_agent;
fi

# more zsh stuff
autoload colors; colors;
autoload -U compinit && compinit -u
autoload zmv
zmodload -a colors
zmodload -a autocomplete
zmodload -a complist
zstyle ':completion:*:default' list-colors ${(s.:.)LS_COLORS}
bindkey -v
bindkey "^R" history-incremental-search-backward


export AWS_REGION=us-east-2

# AWS - connect to EKS cluster
# export EKS_CLUSTER_NAME=$(aws eks list-clusters --region $AWS_REGION | jq -r '.clusters[0]')
# aws sts get-caller-identity && aws eks update-kubeconfig --name $EKS_CLUSTER_NAME --region $AWS_REGION
# kubectl config set-context --current --namespace=$DEFAULT_NAMESPACE
# chmod 600 ~/.kube/config

# setup syntax highlighting (valid commands turn green as you type)
source ~/.oh-my-zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

eval "$(direnv hook zsh)"
