#!/bin/sh

function slack_notification {
    # $1はカラー $2はメッセージ
    curl -X POST -H 'Content-type: application/json' --data "{'attachments':[{'fallback':'fallbackTest','pretext':'Deploy Notification','color':'${2}','fields':[{'title':'${1}','value':'BRANCH:${BRANCH}\n${PIPELINE_URL}'}]},]}" ${SLACK_INCOMING_HOOK}
}