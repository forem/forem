#!/bin/bash

specs=(
  spec/system/internal/admin_bans_or_warns_user
)
num_copies=50

for spec in ${specs[*]}; do
  for i in $(seq 1 $num_copies); do
    copy=${spec}_${i}_spec.rb
    cp ${spec}_spec.rb $copy
  done
done
