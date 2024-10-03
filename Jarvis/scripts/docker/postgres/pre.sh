#!/bin/bash -e

echo -e "\n\n● Pre script for ${JARVIS_CONTAINER_NAME}\n"

echo "→ Creating required directories"

CONFIGS_PATH="${JARVIS_CONFIGS}/${JARVIS_CONTAINER_NAME}/data"
DIRS=(
    "pg_commit_ts"
    "pg_dynshmem"
    "pg_notify"
    "pg_replslot"
    "pg_serial"
    "pg_snapshots"
    "pg_stat"
    "pg_stat_tmp"
    "pg_twophase"
    "pg_tblspc"
    "pg_logical/mappings"
    "pg_logical/snapshots"
)

mkdir -p "${DIRS[@]/#/$CONFIGS_PATH/}"