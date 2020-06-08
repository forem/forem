#!/bin/bash

specs=(
spec/requests/articles/articles
)
num_copies=50

for spec in ${specs[*]}; do
  for i in $(seq 1 $num_copies); do
    copy=${spec}_${i}_spec.rb
    cp ${spec}_spec.rb $copy
  done
done
