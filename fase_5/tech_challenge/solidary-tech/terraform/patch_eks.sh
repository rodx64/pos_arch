#!/bin/bash
set -e

EKS_MAIN=$(find . -path "*/.terraform/modules/eks.eks/main.tf" 2>/dev/null | head -1)

if [ -z "$EKS_MAIN" ]; then
  echo "EKS module not found, skipping patch"
  exit 0
fi

echo "Patching $EKS_MAIN..."

sed -i '/^data "aws_iam_session_context" "current"/,/^}/s/^/# /' "$EKS_MAIN"

sed -i 's/data\.aws_iam_session_context\.current\.issuer_arn/data.aws_caller_identity.current.arn/g' "$EKS_MAIN"

echo "Patch applied to $EKS_MAIN"
