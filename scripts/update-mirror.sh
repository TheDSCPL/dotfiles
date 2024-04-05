#!/usr/bin/env bash
set -euo pipefail
export MERGE_DONE=''

# The main branch in this repo
true ${MAIN_BRANCH:='main'}
# The name of this repo's remote
true ${REMOTE_NAME:='origin'}
# This repo's URL
true ${REMOTE_URL:='git@github.com:TheDSCPL/dotfiles.git'}
# Mirror remote's name
true ${MIRROR_REMOTE_NAME:='mirror'}
# Mirror remote's URL
true ${MIRROR_REMOTE_URL:='git@github.com:sioodmy/dotfiles.git'}
# Mirror remote's main branch
true ${MIRROR_REMOTE_BRANCH:='main'}
# Name of the local branch to which the mirror's main branch is pulled
true ${MIRROR_LOCAL_BRANCH:='mirror-main'}

CURR_MIRROR_REMOTE_URL="$(git remote get-url ${MIRROR_REMOTE_NAME} 2>/dev/null || true)"

# Update or create the local branch that tracks the mirror
if [ -z "${CURR_MIRROR_REMOTE_URL}" ]; then
	echo -n "Adding a read-only remote '${MIRROR_REMOTE_NAME}' with url '${MIRROR_REMOTE_URL}'..."
	git remote add "${MIRROR_REMOTE_NAME}" "${MIRROR_REMOTE_URL}" >/dev/null
	echo ' done'
elif [ "${CURR_MIRROR_REMOTE_URL}" != "${MIRROR_REMOTE_URL}" ]; then
	echo -n "Setting the '${MIRROR_REMOTE_NAME}' remote's url to '${MIRROR_REMOTE_URL}' and making it read-only..."
	git remote set-url "${MIRROR_REMOTE_NAME}" "${MIRROR_REMOTE_URL}" >/dev/null
	echo ' done'
else
	echo "Using read-only remote '${MIRROR_REMOTE_NAME}' with url '${MIRROR_REMOTE_URL}'"
fi
# Mark the mirror remote as read-only by telling git to use an empty push url
git remote set-url --push "${MIRROR_REMOTE_NAME}" '' >/dev/null

echo -n "Fetching '${MIRROR_REMOTE_NAME}/${MIRROR_REMOTE_BRANCH}'..."
# Fetch the remote branch from the mirror
git fetch -q "${MIRROR_REMOTE_NAME}" "${MIRROR_REMOTE_BRANCH}" >/dev/null
echo ' done'
PREV_LOCAL_REV="$(git rev-parse --short "$MIRROR_LOCAL_BRANCH")"
REMOTE_REV="$(git rev-parse --short "${MIRROR_REMOTE_NAME}/${MIRROR_REMOTE_BRANCH}")"

if [ "${PREV_LOCAL_REV}" == "$REMOTE_REV" ]; then
	echo "${MIRROR_LOCAL_BRANCH} (${PREV_LOCAL_REV}) is already up to date"
fi

echo -n "Setting branch '${MIRROR_LOCAL_BRANCH}' HEAD (${PREV_LOCAL_REV:-"didn't exist, so it'll be created"}) to '${MIRROR_REMOTE_NAME}/${MIRROR_REMOTE_BRANCH}' (${REMOTE_REV})..."
# Replace (or create) the mirror local branch with the mirror's remote branch.
# Also sets the upstream of the local copy of the mirror's main branch to this repo.
git branch -f "${MIRROR_LOCAL_BRANCH}" "${MIRROR_REMOTE_NAME}/${MIRROR_REMOTE_BRANCH}" >/dev/null
echo ' done'
# Set the upstream of the main branch
git branch --set-upstream-to="${REMOTE_NAME}/${MIRROR_LOCAL_BRANCH}" "${MIRROR_LOCAL_BRANCH}" >/dev/null
git branch --set-upstream-to="${REMOTE_NAME}/${MAIN_BRANCH}" "${MAIN_BRANCH}" >/dev/null

# Check if the mirror branch is already merged into this repo's main branch
if [ ! -z "$(git branch --merged "${MAIN_BRANCH}" "${MIRROR_LOCAL_BRANCH}")" ]; then
	echo "${MIRROR_LOCAL_BRANCH} is already merged into ${MAIN_BRANCH}"
	exit 0
fi

# Merge the mirror's main into this repo's main branch
CURRENT_BRANCH="$(git branch --show-current 2>/dev/null)"
if [ "${CURRENT_BRANCH}" != "${MAIN_BRANCH}" ]; then (
	# Currently not with this repo's main branch checked-out
	# Using a subshell to trap cleanup code
	set -euo pipefail
	TMP_WORKTREE="$(mktemp -d)"
	trap "rm -f \"${TMP_WORKTREE}\"; echo 'Removed temporary worktree directory'" EXIT
	(
		# Using a subshell to trap cleanup code
		set -euo pipefail
		git worktree add "${TMP_WORKTREE}" "${MAIN_BRANCH}"
		trap "git worktree remove -f \"${TMP_WORKTREE}\" >/dev/null ; echo 'Removed temporary worktree'" EXIT
		(
			# Using a subshell to not change the directory outside it
			set -euo pipefail
			cd "${TMP_WORKTREE}"
			echo "Merging ${MIRROR_LOCAL_BRANCH} into ${MAIN_BRANCH} in a temporary worktree in '${TMP_WORKTREE}'..."
			git merge --no-edit "${MIRROR_LOCAL_BRANCH}"
			export MERGE_DONE=1
		)
	)
) elif [ -z "$(git status --untracked-files=no --porcelain)" ]; then
	# Working directory clean excluding untracked files
	if [ ! -z "$(git status --porcelain)" ]; then
		# But there are untracked files, warn
		echo -n "WARN: There are untracked files in the working tree. Do you wish to continue with the merge? (y/n) "
		stty sane 2>/dev/null || true
		read IGNORE_DIRTY_TREE
		if [ "$IGNORE_DIRTY_TREE" != "y" ] && [ "$IGNORE_DIRTY_TREE" != "Y" ]; then
			exit 1
		fi
	fi
	echo "Merging ${MIRROR_LOCAL_BRANCH} into ${MAIN_BRANCH}..."
	git merge --no-edit "${MIRROR_LOCAL_BRANCH}"
	export MERGE_DONE=1
else
	echo "ERROR: Currently on '${MAIN_BRANCH}', but there are uncommitted changes! Merge of ${MIRROR_LOCAL_BRANCH} into ${MAIN_BRANCH} skipped!" >&2
	exit 1
fi

if [ "${MERGE_DONE}" -eq 1 ]; then
	echo "${REMOTE_NAME}/${MIRROR_LOCAL_BRANCH} was merged into ${MAIN_BRANCH}!"
fi
