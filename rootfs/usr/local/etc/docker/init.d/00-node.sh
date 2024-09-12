#!/usr/bin/env bash
# shellcheck shell=bash
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
##@Version           :  202409121710-git
# @@Author           :  Jason Hempstead
# @@Contact          :  jason@casjaysdev.pro
# @@License          :  WTFPL
# @@ReadME           :  00-node.sh --help
# @@Copyright        :  Copyright: (c) 2024 Jason Hempstead, Casjays Developments
# @@Created          :  Thursday, Sep 12, 2024 17:10 EDT
# @@File             :  00-node.sh
# @@Description      :
# @@Changelog        :  New script
# @@TODO             :  Better documentation
# @@Other            :
# @@Resource         :
# @@Terminal App     :  no
# @@sudo/root        :  no
# @@Template         :  other/start-service
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# shellcheck disable=SC2016
# shellcheck disable=SC2031
# shellcheck disable=SC2120
# shellcheck disable=SC2155
# shellcheck disable=SC2199
# shellcheck disable=SC2317
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# run trap command on exit
trap 'retVal=$?;[ "$SERVICE_IS_RUNNING" != "yes" ] && [ -f "$SERVICE_PID_FILE" ] && rm -Rf "$SERVICE_PID_FILE";exit $retVal' SIGINT SIGTERM EXIT
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# setup debugging - https://www.gnu.org/software/bash/manual/html_node/The-Set-Builtin.html
[ -f "/config/.debug" ] && [ -z "$DEBUGGER_OPTIONS" ] && export DEBUGGER_OPTIONS="$(<"/config/.debug")" || DEBUGGER_OPTIONS="${DEBUGGER_OPTIONS:-}"
{ [ "$DEBUGGER" = "on" ] || [ -f "/config/.debug" ]; } && echo "Enabling debugging" && set -xo pipefail -x$DEBUGGER_OPTIONS && export DEBUGGER="on" || set -o pipefail
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
export PATH="/usr/local/etc/docker/bin:/usr/local/bin:/usr/bin:/usr/sbin:/bin:/sbin"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
SCRIPT_FILE="$0"
SERVICE_NAME="node"
SCRIPT_NAME="$(basename "$SCRIPT_FILE" 2>/dev/null)"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# exit if __start_init_scripts function hasn't been Initialized
if [ ! -f "/run/__start_init_scripts.pid" ]; then
  echo "__start_init_scripts function hasn't been Initialized" >&2
  SERVICE_IS_RUNNING="no"
  exit 1
fi
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# import the functions file
if [ -f "/usr/local/etc/docker/functions/entrypoint.sh" ]; then
  . "/usr/local/etc/docker/functions/entrypoint.sh"
fi
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# import variables
for set_env in "/root/env.sh" "/usr/local/etc/docker/env"/*.sh "/config/env"/*.sh; do
  [ -f "$set_env" ] && . "$set_env"
done
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
printf '%s\n' "# - - - Initializing $SERVICE_NAME - - - #"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Custom functions

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Script to execute
START_SCRIPT="/usr/local/etc/docker/exec/$SERVICE_NAME"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Reset environment before executing service
RESET_ENV="no"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Set the database root dir - [DATABASE_DIR_SQLITE,DATABASE_DIR_REDIS,DATABASE_DIR_POSTGRES,DATABASE_DIR_MARIADB,DATABASE_DIR_COUCHDB,DATABASE_DIR_MONGODB,DATABASE_DIR_SUPABASE]
DATABASE_BASE_DIR="${DATABASE_BASE_DIR:-/data/db}"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Set the database sub directory [sqlite,postgres,mysql,mariadb,redis,couchdb,mongodb,$APPNAME]
DATABASE_SUBDIR="node"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# set the database directory - set by the above variables
DATABASE_DIR="$DATABASE_BASE_DIR/$DATABASE_SUBDIR"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Set webroot
WWW_ROOT_DIR="/usr/share/httpd/default"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Default predefined variables
DATA_DIR="/data/node"   # set data directory
CONF_DIR="/config/node" # set config directory
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# set the containers etc directory
ETC_DIR="/etc/node"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# set the var dir
VAR_DIR=""
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
TMP_DIR="/tmp/node"       # set the temp dir
RUN_DIR="/run/node"       # set scripts pid dir
LOG_DIR="/data/logs/node" # set log directory
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Set the working dir
WORK_DIR="/usr/share/enclosed"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# port which service is listening on
SERVICE_PORT="80"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# User to use to launch service - IE: postgres
RUNAS_USER="root" # normally root
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# User and group in which the service switches to - IE: nginx,apache,mysql,postgres
#SERVICE_USER="node"  # execute command as another user
#SERVICE_GROUP="node" # Set the service group
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Set password length
RANDOM_PASS_USER=""
RANDOM_PASS_ROOT=""
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Set user and group ID
SERVICE_UID="0" # set the user id
SERVICE_GID="0" # set the group id
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# execute command variables - keep single quotes variables will be expanded later
EXEC_CMD_BIN='node'       # command to execute
EXEC_CMD_ARGS='index.cjs' # command arguments
EXEC_PRE_SCRIPT=''        # execute script before
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Is this service a web server
IS_WEB_SERVER="no"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Is this service a database server
IS_DATABASE_SERVICE="yes"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Does this service use a database server
USES_DATABASE_SERVICE="no"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Show message before execute
PRE_EXEC_MESSAGE=""
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Set the wait time to execute __post_execute function - minutes
POST_EXECUTE_WAIT_TIME="1"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Update path var
PATH="$PATH:."
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Lets get containers ip address
IP4_ADDRESS="$(__get_ip4)"
IP6_ADDRESS="$(__get_ip6)"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Where to save passwords to
ROOT_FILE_PREFIX="/config/secure/auth/root" # directory to save username/password for root user
USER_FILE_PREFIX="/config/secure/auth/user" # directory to save username/password for normal user
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# root/admin user info password/random]
root_user_name="${NODE_ROOT_USER_NAME:-}" # root user name
root_user_pass="${NODE_ROOT_PASS_WORD:-}" # root user password
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Normal user info [password/random]
user_name="${NODE_USER_NAME:-}"      # normal user name
user_pass="${NODE_USER_PASS_WORD:-}" # normal user password
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Load variables from config
[ -f "/config/env/node.script.sh" ] && . "/config/env/node.script.sh" # Generated by my dockermgr script
[ -f "/config/env/node.sh" ] && . "/config/env/node.sh"               # Overwrite the variabes
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Additional predefined variables

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Additional variables

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Specifiy custom directories to be created
ADD_APPLICATION_FILES=""
ADD_APPLICATION_DIRS=""
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
APPLICATION_FILES="$LOG_DIR/$SERVICE_NAME.log"
APPLICATION_DIRS="$ETC_DIR $CONF_DIR $LOG_DIR $TMP_DIR $RUN_DIR $VAR_DIR"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Additional config dirs - will be Copied to /etc/$name
ADDITIONAL_CONFIG_DIRS=""
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# define variables that need to be loaded into the service - escape quotes - var=\"value\",other=\"test\"
CMD_ENV=""
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Overwrite based on file/directory
export PORT=${SERVICE_PORT}
export SERVER_API_ROUTES_TIMEOUT_MS=10000
export SERVER_CORS_ORIGINS='*'
export NOTES_MAX_ENCRYPTED_PAYLOAD_LENGTH=5242880
export TASK_DELETE_EXPIRED_NOTES_ENABLED=true
export TASK_DELETE_EXPIRED_NOTES_CRON="*/60 * * * *"
export TASK_DELETE_EXPIRED_NOTES_RUN_ON_STARTUP=true
export STORAGE_DRIVER_FS_LITE_PATH=/data/enclosed
export STORAGE_DRIVER_CLOUDFLARE_KV_BINDING=notes
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Per Application Variables or imports

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Custom commands to run before copying to /config
__run_precopy() {
  # Define environment
  local hostname=${HOSTNAME}
  # Define actions/commands

  # allow custom functions
  if builtin type -t __run_precopy_local | grep -q 'function'; then __run_precopy_local; fi
}
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Custom prerun functions - IE setup WWW_ROOT_DIR
__execute_prerun() {
  # Define environment
  local hostname=${HOSTNAME}
  # Define actions/commands

  # allow custom functions
  if builtin type -t __execute_prerun_local | grep -q 'function'; then __execute_prerun_local; fi
}
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Run any pre-execution checks
__run_pre_execute_checks() {
  # Set variables
  local exitStatus=0
  local pre_execute_checks_MessageST="Running preexecute check for $SERVICE_NAME"   # message to show at start
  local pre_execute_checks_MessageEnd="Finished preexecute check for $SERVICE_NAME" # message to show at completion
  __banner "$pre_execute_checks_MessageST"
  # Put command to execute in parentheses
  {
    true
  }
  exitStatus=$?
  __banner "$pre_execute_checks_MessageEnd: Status $exitStatus"

  # show exit message
  if [ $exitStatus -ne 0 ]; then
    echo "The pre-execution check has failed" >&2
    [ -f "$SERVICE_PID_FILE" ] && rm -Rf "$SERVICE_PID_FILE"
    exit 1
  fi
  # allow custom functions
  if builtin type -t __run_pre_execute_checks_local | grep -q 'function'; then __run_pre_execute_checks_local; fi
  # exit function
  return $exitStatus
}
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# use this function to update config files - IE: change port
__update_conf_files() {
  local exitCode=0                                               # default exit code
  local sysname="${SERVER_NAME:-${FULL_DOMAIN_NAME:-$HOSTNAME}}" # set hostname
  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # delete files
  #__rm ""

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # custom commands

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # replace variables
  # __replace "" "" "$CONF_DIR/node.conf"
  # replace variables recursively
  # __find_replace "" "" "$CONF_DIR"

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # define actions
  [ -d "$WORK_DIR/.data" ] && rm -Rf "$WORK_DIR/.data"
  symlink "$DATA_DIR" "$WORK_DIR/.data"
  # allow custom functions
  if builtin type -t __update_conf_files_local | grep -q 'function'; then __update_conf_files_local; fi
  # exit function
  return $exitCode
}
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# function to run before executing
__pre_execute() {
  local exitCode=0                                               # default exit code
  local sysname="${SERVER_NAME:-${FULL_DOMAIN_NAME:-$HOSTNAME}}" # set hostname
  # execute if directories is empty
  # __is_dir_empty "$CONF_DIR" && true
  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # define actions to run after copying to /config

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # unset unneeded variables
  unset sysname
  # Lets wait a few seconds before continuing
  sleep 5
  # allow custom functions
  if builtin type -t __pre_execute_local | grep -q 'function'; then __pre_execute_local; fi
  # exit function
  return $exitCode
}
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# function to run after executing
__post_execute() {
  local pid=""                                                    # init pid var
  local retVal=0                                                  # set default exit code
  local ctime=${POST_EXECUTE_WAIT_TIME:-1}                        # how long to wait before executing
  local waitTime=$((ctime * 60))                                  # convert minutes to seconds
  local postMessageST="Running post commands for $SERVICE_NAME"   # message to show at start
  local postMessageEnd="Finished post commands for $SERVICE_NAME" # message to show at completion
  # wait
  sleep $waitTime
  # execute commands after waiting
  (
    # show message
    __banner "$postMessageST"
    # commands to execute
    sleep 5
    # show exit message
    __banner "$postMessageEnd: Status $retVal"
  ) 2>"/dev/stderr" | tee -p -a "/data/logs/init.txt" &
  pid=$!
  ps ax | awk '{print $1}' | grep -v grep | grep -q "$execPid$" && retVal=0 || retVal=10
  # allow custom functions
  if builtin type -t __post_execute_local | grep -q 'function'; then __post_execute_local; fi
  # exit function
  return $retVal
}
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# use this function to update config files - IE: change port
__pre_message() {
  local exitCode=0
  [ -n "$PRE_EXEC_MESSAGE" ] && eval echo "$PRE_EXEC_MESSAGE"
  # execute commands

  # allow custom functions
  if builtin type -t __pre_message_local | grep -q 'function'; then __pre_message_local; fi
  # exit function
  return $exitCode
}
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# use this function to setup ssl support
__update_ssl_conf() {
  local exitCode=0
  local sysname="${SERVER_NAME:-${FULL_DOMAIN_NAME:-$HOSTNAME}}" # set hostname
  # execute commands

  # allow custom functions
  if builtin type -t __update_ssl_conf_local | grep -q 'function'; then __update_ssl_conf_local; fi
  # set exitCode
  return $exitCode
}
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
__create_service_env() {
  local exitCode=0
  if [ ! -f "/config/env/${SERVICE_NAME:-$SCRIPT_NAME}.sh" ]; then
    cat <<EOF | tee -p "/config/env/${SERVICE_NAME:-$SCRIPT_NAME}.sh" &>/dev/null
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# root/admin user info [password/random]
#ENV_ROOT_USER_NAME="${ENV_ROOT_USER_NAME:-$NODE_ROOT_USER_NAME}"   # root user name
#ENV_ROOT_USER_PASS="${ENV_ROOT_USER_NAME:-$NODE_ROOT_PASS_WORD}"   # root user password
#root_user_name="${ENV_ROOT_USER_NAME:-$root_user_name}"                              #
#root_user_pass="${ENV_ROOT_USER_PASS:-$root_user_pass}"                              #
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
#Normal user info [password/random]
#ENV_USER_NAME="${ENV_USER_NAME:-$NODE_USER_NAME}"                  #
#ENV_USER_PASS="${ENV_USER_PASS:-$NODE_USER_PASS_WORD}"             #
#user_name="${ENV_USER_NAME:-$user_name}"                                             # normal user name
#user_pass="${ENV_USER_PASS:-$user_pass}"                                             # normal user password

EOF
  fi
  if [ ! -f "/config/env/${SERVICE_NAME:-$SCRIPT_NAME}.local.sh" ]; then
    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    __run_precopy_local() { true; }
    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    __execute_prerun_local() { true; }
    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    __run_pre_execute_checks_local() { true; }
    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    __update_conf_files_local() { true; }
    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    __pre_execute_local() { true; }
    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    __post_execute_local() { true; }
    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    __pre_message_local() { true; }
    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    __update_ssl_conf_local() { true; }
    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  fi
  __file_exists_with_content "/config/env/${SERVICE_NAME:-$SCRIPT_NAME}.sh" || exitCode=$((exitCode + 1))
  __file_exists_with_content "/config/env/${SERVICE_NAME:-$SCRIPT_NAME}.local.sh" || exitCode=$((exitCode + 1))
  return $exitCode
}
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# script to start server
__run_start_script() {
  local runExitCode=0
  local workdir="$(eval echo "${WORK_DIR:-}")"                   # expand variables
  local cmd="$(eval echo "${EXEC_CMD_BIN:-}")"                   # expand variables
  local args="$(eval echo "${EXEC_CMD_ARGS:-}")"                 # expand variables
  local name="$(eval echo "${EXEC_CMD_NAME:-}")"                 # expand variables
  local pre="$(eval echo "${EXEC_PRE_SCRIPT:-}")"                # expand variables
  local extra_env="$(eval echo "${CMD_ENV//,/ }")"               # expand variables
  local lc_type="$(eval echo "${LANG:-${LC_ALL:-$LC_CTYPE}}")"   # expand variables
  local home="$(eval echo "${workdir//\/root/\/tmp\/docker}")"   # expand variables
  local path="$(eval echo "$PATH")"                              # expand variables
  local message="$(eval echo "")"                                # expand variables
  local sysname="${SERVER_NAME:-${FULL_DOMAIN_NAME:-$HOSTNAME}}" # set hostname
  [ -f "$CONF_DIR/$SERVICE_NAME.exec_cmd.sh" ] && . "$CONF_DIR/$SERVICE_NAME.exec_cmd.sh"
  #
  if [ -z "$cmd" ]; then
    __post_execute 2>"/dev/stderr" | tee -p -a "/data/logs/init.txt"
    retVal=$?
    echo "Initializing $SCRIPT_NAME has completed"
    exit $retVal
  else
    # ensure the command exists
    if [ ! -x "$cmd" ]; then
      echo "$name is not a valid executable"
      return 2
    fi
    # check and exit if already running
    if __proc_check "$name" || __proc_check "$cmd"; then
      echo "$name is already running" >&2
      return 0
    else
      # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
      # show message if env exists
      if [ -n "$cmd" ]; then
        [ -n "$SERVICE_USER" ] && echo "Setting up $cmd to run as $SERVICE_USER" || SERVICE_USER="root"
        [ -n "$SERVICE_PORT" ] && echo "$name will be running on port $SERVICE_PORT" || SERVICE_PORT=""
      fi
      if [ -n "$pre" ] && [ -n "$(command -v "$pre" 2>/dev/null)" ]; then
        export cmd_exec="$pre $cmd $args"
        message="Starting service: $name $args through $pre"
      else
        export cmd_exec="$cmd $args"
        message="Starting service: $name $args"
      fi
      [ -n "$su_exec" ] && echo "using $su_exec" | tee -a -p "/data/logs/init.txt"
      echo "$message" | tee -a -p "/data/logs/init.txt"
      su_cmd touch "$SERVICE_PID_FILE"
      if [ "$RESET_ENV" = "yes" ]; then
        env_command="$(echo "env -i HOME=\"$home\" LC_CTYPE=\"$lc_type\" PATH=\"$path\" HOSTNAME=\"$sysname\" USER=\"${SERVICE_USER:-$RUNAS_USER}\" $extra_env")"
        execute_command="$(__trim "$su_exec $env_command $cmd_exec")"
        if [ ! -f "$START_SCRIPT" ]; then
          cat <<EOF >"$START_SCRIPT"
#!/usr/bin/env bash
trap 'exitCode=\$?;[ \$exitCode -ne 0 ] && [ -f "\$SERVICE_PID_FILE" ] && rm -Rf "\$SERVICE_PID_FILE";exit \$exitCode' EXIT
#
set -Eeo pipefail
# Setting up $cmd to run as ${SERVICE_USER:-root} with env
retVal=10
cmd="$cmd"
SERVICE_NAME="$SERVICE_NAME"
SERVICE_PID_FILE="$SERVICE_PID_FILE"
$execute_command 2>"/dev/stderr" >>"$LOG_DIR/$SERVICE_NAME.log" &
execPid=\$!
sleep 2
checkPID="\$(ps ax | awk '{print \$1}' | grep -v grep | grep "\$execPid$" || false)"
[ -n "\$execPid"  ] && [ -n "\$checkPID" ] && echo "\$execPid" >"\$SERVICE_PID_FILE" && retVal=0 || retVal=10
[ "\$retVal" = 0 ] && echo "\$cmd has been started" || echo "Failed to start $execute_command" >&2
exit \$retVal

EOF
        fi
      else
        if [ ! -f "$START_SCRIPT" ]; then
          execute_command="$(__trim "$su_exec $cmd_exec")"
          cat <<EOF >"$START_SCRIPT"
#!/usr/bin/env bash
trap 'exitCode=\$?;[ \$exitCode -ne 0 ] && [ -f "\$SERVICE_PID_FILE" ] && rm -Rf "\$SERVICE_PID_FILE";exit \$exitCode' EXIT
#
set -Eeo pipefail
# Setting up $cmd to run as ${SERVICE_USER:-root}
retVal=10
cmd="$cmd"
SERVICE_NAME="$SERVICE_NAME"
SERVICE_PID_FILE="$SERVICE_PID_FILE"
$execute_command 2>>"/dev/stderr" >>"$LOG_DIR/$SERVICE_NAME.log" &
execPid=\$!
sleep 2
checkPID="\$(ps ax | awk '{print \$1}' | grep -v grep | grep "\$execPid$" || false)"
[ -n "\$execPid"  ] && [ -n "\$checkPID" ] && echo "\$execPid" >"\$SERVICE_PID_FILE" && retVal=0 || retVal=10
[ "\$retVal" = 0 ] && echo "\$cmd has been started" || echo "Failed to start $execute_command" >&2 >&2
exit \$retVal

EOF
        fi
      fi
    fi
    [ -x "$START_SCRIPT" ] || chmod 755 -Rf "$START_SCRIPT"
    [ "$CONTAINER_INIT" = "yes" ] || eval sh -c "$START_SCRIPT"
    runExitCode=$?
  fi
  return $runExitCode
}
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# username and password actions
__run_secure_function() {
  local filesperms
  if [ -n "$user_name" ] || [ -n "$user_pass" ]; then
    for filesperms in "${USER_FILE_PREFIX}"/*; do
      if [ -e "$filesperms" ]; then
        chmod -Rf 600 "$filesperms"
        chown -Rf $SERVICE_USER:$SERVICE_USER "$filesperms" 2>/dev/null
      fi
    done 2>/dev/null | tee -p -a "/data/logs/init.txt"
  fi
  if [ -n "$root_user_name" ] || [ -n "$root_user_pass" ]; then
    for filesperms in "${ROOT_FILE_PREFIX}"/*; do
      if [ -e "$filesperms" ]; then
        chmod -Rf 600 "$filesperms"
        chown -Rf $SERVICE_USER:$SERVICE_USER "$filesperms" 2>/dev/null
      fi
    done 2>/dev/null | tee -p -a "/data/logs/init.txt"
  fi
  unset filesperms
}
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Allow ENV_ variable - Import env file
__file_exists_with_content "/config/env/${SERVICE_NAME:-$SCRIPT_NAME}.sh" && . "/config/env/${SERVICE_NAME:-$SCRIPT_NAME}.sh"
__file_exists_with_content "/config/env/${SERVICE_NAME:-$SCRIPT_NAME}.local.sh" && . "/config/env/${SERVICE_NAME:-$SCRIPT_NAME}.local.sh"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
SERVICE_EXIT_CODE=0 # default exit code
# application specific
EXEC_CMD_NAME="$(basename "$EXEC_CMD_BIN")"                                # set the binary name
SERVICE_PID_FILE="/run/init.d/$EXEC_CMD_NAME.pid"                          # set the pid file location
SERVICE_PID_NUMBER="$(__pgrep)"                                            # check if running
EXEC_CMD_BIN="$(type -P "$EXEC_CMD_BIN" || echo "$EXEC_CMD_BIN")"          # set full path
EXEC_PRE_SCRIPT="$(type -P "$EXEC_PRE_SCRIPT" || echo "$EXEC_PRE_SCRIPT")" # set full path
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Only run check
__check_service "$1" && SERVICE_IS_RUNNING=yes
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# ensure needed directories exists
[ -d "$LOG_DIR" ] || mkdir -p "$LOG_DIR"
[ -d "$RUN_DIR" ] || mkdir -p "$RUN_DIR"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# create auth directories
[ -n "$USER_FILE_PREFIX" ] && { [ -d "$USER_FILE_PREFIX" ] || mkdir -p "$USER_FILE_PREFIX"; }
[ -n "$ROOT_FILE_PREFIX" ] && { [ -d "$ROOT_FILE_PREFIX" ] || mkdir -p "$ROOT_FILE_PREFIX"; }
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
[ -n "$RUNAS_USER" ] || RUNAS_USER="root"
[ -n "$SERVICE_USER" ] || SERVICE_USER="$RUNAS_USER"
[ -n "$SERVICE_GROUP" ] || SERVICE_GROUP="${SERVICE_USER:-$RUNAS_USER}"
[ "$IS_WEB_SERVER" = "yes" ] && RESET_ENV="yes" && __is_htdocs_mounted
[ "$IS_WEB_SERVER" = "yes" ] && [ -z "$SERVICE_PORT" ] && SERVICE_PORT="80"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Database env
if [ "$IS_DATABASE_SERVICE" = "yes" ] || [ "$USES_DATABASE_SERVICE" = "yes" ]; then
  RESET_ENV="no"
  DATABASE_CREATE="${ENV_DATABASE_CREATE:-$DATABASE_CREATE}"
  DATABASE_USER="${ENV_DATABASE_USER:-${DATABASE_USER:-$user_name}}"
  DATABASE_PASSWORD="${ENV_DATABASE_PASSWORD:-${DATABASE_PASSWORD:-$user_pass}}"
  DATABASE_ROOT_USER="${ENV_DATABASE_ROOT_USER:-${DATABASE_ROOT_USER:-$root_user_name}}"
  DATABASE_ROOT_PASSWORD="${ENV_DATABASE_ROOT_PASSWORD:-${DATABASE_ROOT_PASSWORD:-$root_user_pass}}"
  if [ -n "$DATABASE_PASSWORD" ] && [ ! -f "${USER_FILE_PREFIX}/db_pass_user" ]; then
    echo "$DATABASE_PASSWORD" >"${USER_FILE_PREFIX}/db_pass_user"
  fi
  if [ -n "$DATABASE_ROOT_PASSWORD" ] && [ ! -f "${ROOT_FILE_PREFIX}/db_pass_root" ]; then
    echo "$DATABASE_ROOT_PASSWORD" >"${ROOT_FILE_PREFIX}/db_pass_root"
  fi
fi
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Allow variables via imports - Overwrite existing
[ -f "/config/env/${SERVICE_NAME:-$SCRIPT_NAME}.sh" ] && . "/config/env/${SERVICE_NAME:-$SCRIPT_NAME}.sh"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# set password to random if variable is random
[ "$user_pass" = "random" ] && user_pass="$(__random_password ${RANDOM_PASS_USER:-16})"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
[ "$root_user_pass" = "random" ] && root_user_pass="$(__random_password ${RANDOM_PASS_ROOT:-16})"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Allow setting initial users and passwords via environment and save to file
[ -n "$user_name" ] && echo "$user_name" >"${USER_FILE_PREFIX}/${SERVICE_NAME}_name"
[ -n "$user_pass" ] && echo "$user_pass" >"${USER_FILE_PREFIX}/${SERVICE_NAME}_pass"
[ -n "$root_user_name" ] && echo "$root_user_name" >"${ROOT_FILE_PREFIX}/${SERVICE_NAME}_name"
[ -n "$root_user_pass" ] && echo "$root_user_pass" >"${ROOT_FILE_PREFIX}/${SERVICE_NAME}_pass"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# create needed dirs
[ -d "$LOG_DIR" ] || mkdir -p "$LOG_DIR"
[ -d "$RUN_DIR" ] || mkdir -p "$RUN_DIR"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Allow per init script usernames and passwords
__file_exists_with_content "${USER_FILE_PREFIX}/${SERVICE_NAME}_name" && user_name="$(<"${USER_FILE_PREFIX}/${SERVICE_NAME}_name")"
__file_exists_with_content "${USER_FILE_PREFIX}/${SERVICE_NAME}_pass" && user_pass="$(<"${USER_FILE_PREFIX}/${SERVICE_NAME}_pass")"
__file_exists_with_content "${ROOT_FILE_PREFIX}/${SERVICE_NAME}_name" && root_user_name="$(<"${ROOT_FILE_PREFIX}/${SERVICE_NAME}_name")"
__file_exists_with_content "${ROOT_FILE_PREFIX}/${SERVICE_NAME}_pass" && root_user_pass="$(<"${ROOT_FILE_PREFIX}/${SERVICE_NAME}_pass")"
__file_exists_with_content "${USER_FILE_PREFIX}/db_pass_user" && DATABASE_PASSWORD="$(<"${USER_FILE_PREFIX}/db_pass_user")"
__file_exists_with_content "${ROOT_FILE_PREFIX}/db_pass_root" && DATABASE_ROOT_PASSWORD="$(<"${ROOT_FILE_PREFIX}/db_pass_root")"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# set hostname for script
sysname="${SERVER_NAME:-${FULL_DOMAIN_NAME:-$HOSTNAME}}"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
__create_service_env
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Setup /config directories
__init_config_etc
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# pre-run function
__execute_prerun
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# create user if needed
__create_service_user "$SERVICE_USER" "$SERVICE_GROUP" "${WORK_DIR:-/home/$SERVICE_USER}" "${SERVICE_UID:-}" "${SERVICE_GID:-}"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Modify user if needed
__set_user_group_id $SERVICE_USER ${SERVICE_UID:-} ${SERVICE_GID:-}
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Create base directories
__setup_directories
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# set switch user command
__switch_to_user
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Initialize the home/working dir
__init_working_dir
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# show init message
__pre_message
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
#
__initialize_db_users
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Initialize ssl
__update_ssl_conf
__update_ssl_certs
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Set permissions in ${USER_FILE_PREFIX} and ${ROOT_FILE_PREFIX}
__run_secure_function
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
__run_precopy
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Copy /config to /etc
for config_2_etc in $CONF_DIR $ADDITIONAL_CONFIG_DIRS; do
  __initialize_system_etc "$config_2_etc" 2>/dev/stderr | tee -p -a "/data/logs/init.txt"
done
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Replace variables
__initialize_replace_variables "$ETC_DIR" "$CONF_DIR" "$ADDITIONAL_CONFIG_DIRS" "$WWW_ROOT_DIR"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
#
__initialize_database
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Updating config files
__update_conf_files
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# run the pre execute commands
__pre_execute
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Set permissions
__fix_permissions "$SERVICE_USER" "$SERVICE_GROUP"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
#
__run_pre_execute_checks 2>/dev/stderr | tee -a -p "/data/logs/entrypoint.log" "/data/logs/init.txt" || return 20
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
__run_start_script 2>>/dev/stderr | tee -p -a "/data/logs/entrypoint.log"
errorCode=$?
if [ -n "$EXEC_CMD_BIN" ]; then
  if [ "$errorCode" -eq 0 ]; then
    SERVICE_EXIT_CODE=0
    SERVICE_IS_RUNNING="yes"
  else
    SERVICE_EXIT_CODE=$errorCode
    SERVICE_IS_RUNNING="${SERVICE_IS_RUNNING:-no}"
    [ -s "$SERVICE_PID_FILE" ] || rm -Rf "$SERVICE_PID_FILE"
  fi
  SERVICE_EXIT_CODE=0
fi
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# start the post execute function in background
__post_execute 2>"/dev/stderr" | tee -p -a "/data/logs/init.txt" &
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
__banner "Initializing of $SERVICE_NAME has completed with statusCode: $SERVICE_EXIT_CODE" | tee -p -a "/data/logs/entrypoint.log" "/data/logs/init.txt"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
exit $SERVICE_EXIT_CODE
