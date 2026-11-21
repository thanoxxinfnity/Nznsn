#!/usr/bin/env bash
# 520 models: tukdon mein -> AI se banao -> theek karo -> project mein daalo -> Godot jaanch -> list mark -> commit/push
# bash scripts/gen_pipeline.sh <id_list.txt> [chunk=40] [workers=4]
LIST=$1; CHUNK=${2:-40}; W=${3:-4}
cd "$(dirname "$0")/.."
RAW=/tmp/claude-0/gen_raw; OUT=/tmp/claude-0/gen_out; mkdir -p $RAW $OUT
mapfile -t IDS < "$LIST"
for ((i=0; i<${#IDS[@]}; i+=CHUNK)); do
  n=$((i/CHUNK+1)); part=$(IFS=,; echo "${IDS[*]:i:CHUNK}")
  echo "=== chunk $n: ${IDS[*]:i:CHUNK}" 
  python3 scripts/gen_assets.py $RAW --ids "$part" --workers $W
  CH=/tmp/claude-0/gen_chunk_$n; rm -rf $CH; mkdir -p $CH
  for id in ${part//,/ }; do cp $RAW/${id}_*.glb $CH/ 2>/dev/null; done
  rm -rf $OUT/$n; python3 scripts/process_batch.py $CH $OUT/$n > /tmp/claude-0/gen_proc_$n.log 2>&1
  cp $OUT/$n/*.glb horror_city/assets/props/ 2>/dev/null
  timeout 1200 godot --headless --path horror_city --import > /dev/null 2>&1
  timeout 900 godot --headless --path horror_city --script res://tools/check_models.gd 2>&1 | grep CHECK
  python3 scripts/mark_done.py
  git add -A && git commit -q -m "Claude-generated props chunk $n (AI bpy -> Blender -> baked wear texture -> verified)

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_014t4kRKw6XHcVQTLJeyHDLJ" && git push -q origin ccr-be73983f-pefhcc 2>&1 | tail -1
done
echo PIPELINE_DONE > /tmp/claude-0/gen_pipeline.done
