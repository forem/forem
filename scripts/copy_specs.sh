#!/bin/bash

specs=(
  spec/system/internal/admin_bans_or_warns_user
  spec/system/notifications/notifications_page
  spec/system/internal/admin_manages_organizations
  spec/system/articles/user_visits_article_stats
)
num_copies=10

for spec in ${specs[*]}; do
  for i in $(seq 1 $num_copies); do
    copy=${spec}_${i}_spec.rb
    cp ${spec}_spec.rb $copy
  done
done
