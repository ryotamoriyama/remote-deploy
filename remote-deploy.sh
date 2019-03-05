#!/bin/sh

#.env読み込み
source ./.env

#slack通知関数
source ./slack_notification.sh

# pipelineのURL
PIPELINE_URL="${PIPELINE_RESULT_URL}${1}"

#初期設定がされていない場合
if [ ! -e .git ]; then
    #リポジトリクローン
    sudo GIT_SSH_COMMAND="ssh -i ${IDENTITY_FILE}" git clone ${REPOSITORY}

    #失敗時の処理
    if [ $? -ne 0 ]; then
        slack_notification 'Error:Cloning failed' '#ff0000'
        exit 1
    fi

    git checkout -b ${BRANCH}
fi

#Nodeのインストールチェック
if !(type "node" > /dev/null 2>&1); then
    sudo apt install -y nodejs npm
    sudo npm install n -g
    sudo n "v${NODE_VER}"
    sudo npm install -g "npm@${NPM_VER}"
    sudo apt purge -y nodejs npm
    sudo exec $SHELL -l
fi

#リポジトリからプルしてくる
sudo GIT_SSH_COMMAND="ssh -i ${IDENTITY_FILE}" git pull origin ${BRANCH}

#ビルド
sudo eval ${BUILD_COMMAND}

#ビルド失敗時は通知をして終了
if [ $? -ne 0 ]; then
    slack_notification 'Error:Building failed' '#ff0000'
    exit 1
fi

#rsync
for PATH in $(echo "$RSYNC_DIRS" | tr ',' '\n')
do
    RSYNC_FROM=${PATH%%:*}
    RSYNC_TO=${PATH##*:}
    rsync -avr --delete ${RSYNC_FROM} ${RSYNC_TO}
done

#通知

if [ $? -ne 0 ]; then
    slack_notification 'Error:rsync failed' '#ff0000'
    exit 1
else
    slack_notification 'SUCCESS' '#00FF00'
fi

