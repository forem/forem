#!/bin/bash

specs=(
spec/system/user/user_settings_response_templates
)
num_copies=200

for spec in ${specs[*]}; do
  for i in $(seq 1 $num_copies); do
    copy=${spec}_${i}_spec.rb
    cp ${spec}_spec.rb $copy
  done
done
