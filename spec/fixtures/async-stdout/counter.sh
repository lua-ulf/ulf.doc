#!/bin/bash

start=$1
end=$2
max_wait_time_ms=$3

for ((i = start; i <= end; i++)); do
  wait_time_ms=$((RANDOM % max_wait_time_ms + 1))          # Random time between 1 and max_wait_time_ms
  wait_time_s=$(echo "scale=3; $wait_time_ms / 1000" | bc) # Convert to seconds
  printf "%2d: %4d ms\n" "$i" "$wait_time_ms"
  # echo "$i - ${wait_time_ms}ms"
  sleep "$wait_time_s"
done
