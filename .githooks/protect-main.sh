#!/usr/bin/env sh
# protect-main.sh — giữ nhánh chính sạch. Nguồn: arcozy-skills/githooks/.
#
# Đây là lớp CỨNG ở tầng git: chặn cả commit/push của người lẫn của mọi agent, kể cả
# khi hook Claude bị tắt. Lớp mềm tương ứng là scripts/git-workflow-guard.cjs.
#
# Gọi từ:
#   .githooks/pre-commit  (hoặc .husky/pre-commit) →  sh .githooks/protect-main.sh commit
#   .githooks/pre-push    (hoặc .husky/pre-push)   →  sh .githooks/protect-main.sh push
#
# Khẩn cấp: git commit --no-verify  ·  git push --no-verify
# Đổi danh sách nhánh được bảo vệ: PROTECTED_BRANCHES="main release" (env hoặc git config).
set -u

MODE="${1:-commit}"
PROTECTED="${PROTECTED_BRANCHES:-main master}"

is_protected() {
  for b in $PROTECTED; do
    [ "$1" = "$b" ] && return 0
  done
  return 1
}

hint() {
  echo "" >&2
  echo "   Tạo nhánh rồi làm ở đó:" >&2
  echo "     git checkout -b feature/<mo-ta>   # tính năng mới" >&2
  echo "     git checkout -b fix/<mo-ta>       # sửa bug" >&2
  echo "     git checkout -b chore/<mo-ta>     # tooling/config/docs" >&2
  echo "" >&2
  echo "   Về nhánh chính bằng PR: gh pr create → review → merge." >&2
  echo "   Nhiều phiên Claude cùng thư mục → EnterWorktree để cách ly." >&2
  echo "   Khẩn cấp (không khuyến khích): thêm --no-verify" >&2
  echo "" >&2
}

if [ "$MODE" = "commit" ]; then
  branch="$(git symbolic-ref --short HEAD 2>/dev/null || echo '')"
  if is_protected "$branch"; then
    echo "" >&2
    echo "⛔ pre-commit: không commit thẳng vào '$branch'." >&2
    hint
    exit 1
  fi
  exit 0
fi

# push: git đẩy từng dòng "<local_ref> <local_sha> <remote_ref> <remote_sha>" qua stdin.
while read -r _local_ref _local_sha remote_ref _remote_sha; do
  [ -z "${remote_ref:-}" ] && continue
  target="${remote_ref#refs/heads/}"
  if is_protected "$target"; then
    echo "" >&2
    echo "⛔ pre-push: cấm push thẳng vào '$target' — nhánh chính chỉ nhận qua PR." >&2
    hint
    exit 1
  fi
done

exit 0
