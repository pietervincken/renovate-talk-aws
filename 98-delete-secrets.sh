#!/bin/bash

aws secretsmanager delete-secret --secret-id github-private-key     --no-cli-pager --recovery-window-in-days 7
aws secretsmanager delete-secret --secret-id github-public-key      --no-cli-pager --recovery-window-in-days 7
aws secretsmanager delete-secret --secret-id github-known-hosts     --no-cli-pager --recovery-window-in-days 7
aws secretsmanager delete-secret --secret-id github-pat             --no-cli-pager --recovery-window-in-days 7
aws secretsmanager delete-secret --secret-id github-trigger-secret  --no-cli-pager --recovery-window-in-days 7

# aws secretsmanager restore-secret --secret-id github-private-key     --no-cli-pager
# aws secretsmanager restore-secret --secret-id github-public-key      --no-cli-pager
# aws secretsmanager restore-secret --secret-id github-known-hosts     --no-cli-pager
# aws secretsmanager restore-secret --secret-id github-pat             --no-cli-pager
# aws secretsmanager restore-secret --secret-id github-trigger-secret  --no-cli-pager