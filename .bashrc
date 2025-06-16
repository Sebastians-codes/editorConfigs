# Bash Profile - Git & GitHub Functions

# Basic Git aliases
alias gs='git status'
alias ga='git add'
alias gaa='git add .'
alias gc='git commit -m'
alias gps='git push'
alias gpl='git pull'
alias gst='git stash'
alias gstp='git stash pop'
alias gstl='git stash list'
alias gstd='git stash drop'

# Create new branch and push to origin
gnewb() {
    if [ -z "$1" ]; then
        echo "Usage: gnewb <branch-name>"
        echo "Creates a new branch and pushes it to origin"
        return 1
    fi
    
    local branch_name="$1"
    echo "🌿 Creating and switching to branch: $branch_name"
    
    if git checkout -b "$branch_name"; then
        echo "🚀 Pushing branch to origin..."
        if git push -u origin "$branch_name"; then
            echo "✅ Branch '$branch_name' created and pushed!"
        else
            echo "❌ Failed to push branch"
        fi
    else
        echo "❌ Failed to create branch"
    fi
}

# Switch to existing branch
gco() {
    if [ -z "$1" ]; then
        echo "Usage: gco <branch-name>"
        echo "Switch to an existing branch"
        return 1
    fi
    
    local branch_name="$1"
    echo "🔄 Switching to branch: $branch_name"
    
    if git checkout "$branch_name"; then
        echo "✅ Switched to branch '$branch_name'"
    else
        echo "❌ Failed to switch to branch '$branch_name'"
        echo "💡 Branch might not exist. Use 'gnewb $branch_name' to create it."
    fi
}

# List all branches
gb() {
    echo "📋 All branches:"
    git --no-pager branch -a
}

# List local branches only
gbl() {
    echo "📋 Local branches:"
    git --no-pager branch
}

# Delete branch (local and remote)
gdel() {
    if [ -z "$1" ]; then
        echo "Usage: gdel <branch-name>"
        echo "Delete branch locally and remotely"
        return 1
    fi
    
    local branch_name="$1"
    echo "🗑️  Deleting branch: $branch_name"
    
    # Switch to main if we're on the branch we want to delete
    local current_branch=$(git branch --show-current)
    if [ "$current_branch" = "$branch_name" ]; then
        echo "🔄 Switching to main first..."
        git checkout main
    fi
    
    # Delete local branch
    if git branch -d "$branch_name"; then
        echo "✅ Local branch '$branch_name' deleted"
        
        # Try to delete remote branch
        if git push origin --delete "$branch_name" 2>/dev/null; then
            echo "✅ Remote branch '$branch_name' deleted"
        else
            echo "⚠️  Remote branch '$branch_name' might not exist or already deleted"
        fi
    else
        echo "❌ Failed to delete local branch. Use 'git branch -D $branch_name' to force delete."
    fi
}

# Create new GitHub repository
gnewrepo() {
    if [ -z "$1" ]; then
        echo "Usage: gnewrepo <repository-name> [description]"
        echo "Creates a private GitHub repository and sets it as remote origin"
        return 1
    fi
    
    local repo_name="$1"
    local description="${2:-Created via command line}"
    
    echo "🚀 Creating private repository: $repo_name"
    
    if gh repo create "$repo_name" --private --description "$description"; then
        echo "✅ Repository created on GitHub"
        
        if [ ! -d ".git" ]; then
            git init
            echo "📁 Initialized local git repository"
        fi
        
        # Remove origin if it already exists
        if git remote get-url origin &>/dev/null; then
            echo "🔄 Removing existing origin remote"
            git remote remove origin
        fi
        
        local username=$(gh api user --jq .login)
        git remote add origin "https://github.com/$username/$repo_name.git"
        echo "🔗 Remote origin added"
        
        # Check if there are files to commit
        if [ "$(ls -A)" ]; then
            echo "📁 Files found in directory"
            read -p "Create initial commit with current files? (y/n): " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                git add .
                git commit -m "Initial commit"
                git branch -M main
                git push -u origin main
                echo "🎉 Initial commit pushed!"
            fi
        else
            echo "📁 No files in current directory"
        fi
        
        echo "🌐 Repository URL: https://github.com/$username/$repo_name"
    else
        echo "❌ Failed to create repository"
        return 1
    fi
}

# Create Pull Request
gpr() {
    if [ -z "$1" ]; then
        echo "Usage: gpr <title> [body] [base]"
        echo "Creates a PR from current branch"
        return 1
    fi
    
    local title="$1"
    local body="${2:-}"
    local base="${3:-main}"
    local current_branch=$(git branch --show-current)
    
    echo "🚀 Creating PR: $title"
    echo "📝 From: $current_branch → $base"
    
    if gh pr create --title "$title" --body "$body" --base "$base"; then
        echo "✅ PR created successfully!"
        gh pr view --web
    else
        echo "❌ Failed to create PR"
        return 1
    fi
}

# List Pull Requests
prs() {
    echo "📋 Open Pull Requests:"
    gh pr list
}

# View specific PR
prv() {
    if [ -z "$1" ]; then
        echo "Usage: prv <pr-number>"
        echo "View details of a specific PR"
        return 1
    fi
    
    local pr_number="$1"
    echo "🔍 Viewing PR #$pr_number:"
    gh pr view "$pr_number"
}

# Approve PR
prapprove() {
    if [ -z "$1" ]; then
        echo "Usage: prapprove <pr-number> [comment]"
        echo "Approve a PR with optional comment"
        return 1
    fi
    
    local pr_number="$1"
    local comment="${2:-LGTM! ✅}"
    
    echo "✅ Approving PR #$pr_number..."
    gh pr review "$pr_number" --approve --body "$comment"
    echo "🎉 PR #$pr_number approved!"
}

# Request changes on PR
prchanges() {
    if [ -z "$1" ] || [ -z "$2" ]; then
        echo "Usage: prchanges <pr-number> <comment>"
        echo "Request changes on a PR with required comment"
        return 1
    fi
    
    local pr_number="$1"
    local comment="$2"
    
    echo "📝 Requesting changes on PR #$pr_number..."
    gh pr review "$pr_number" --request-changes --body "$comment"
    echo "✏️  Changes requested on PR #$pr_number"
}

# Merge PR
gmerge() {
    local merge_type="${1:-merge}"
    
    case $merge_type in
        "squash"|"s")
            echo "🔄 Squash merging PR..."
            gh pr merge --squash --delete-branch
            ;;
        "rebase"|"r")
            echo "🔄 Rebase merging PR..."
            gh pr merge --rebase --delete-branch
            ;;
        "merge"|"m"|*)
            echo "🔄 Merge committing PR..."
            gh pr merge --merge --delete-branch
            ;;
    esac
    
    if [ $? -eq 0 ]; then
        echo "✅ PR merged and branch deleted!"
        git checkout main
        git pull origin main
        echo "🔄 Switched to main and pulled latest changes"
    fi
}

# Quick aliases for PR operations
alias prl='gh pr list'
alias prc='gh pr checks'
alias prd='gh pr diff'
alias prco='gh pr checkout'

# Help function - lists all custom Git/GitHub functions
ghelp() {
    echo ""
    echo "=== Git & GitHub Helper Functions ==="
    echo ""
    echo -e "\033[33mBASIC GIT COMMANDS:\033[0m"
    echo "  gs              - git status"
    echo "  ga <files>      - git add <files>"
    echo "  gaa             - git add . (add all files)"
    echo "  gc <message>    - git commit -m <message>"
    echo "  gps             - git push"
    echo "  gpl             - git pull"
    echo "  gst             - git stash"
    echo "  gstp            - git stash pop"
    echo "  gstl            - git stash list"
    echo "  gstd            - git stash drop"
    
    echo ""
    echo -e "\033[33mBRANCH MANAGEMENT:\033[0m"
    echo "  gnewb <name>    - Create new branch and push to origin"
    echo "                    Example: gnewb feature-login"
    echo "  gco <name>      - Switch to existing branch"
    echo "                    Example: gco main"
    echo "  gb              - List all branches (local and remote)"
    echo "  gbl             - List local branches only"
    echo "  gdel <name>     - Delete branch (local and remote)"
    echo "                    Example: gdel old-feature"
    
    echo ""
    echo -e "\033[33mREPOSITORY MANAGEMENT:\033[0m"
    echo "  gnewrepo <name> [description]"
    echo "                  - Create new private GitHub repo and set remote"
    echo "                    Example: gnewrepo my-project 'Cool new app'"
    
    echo ""
    echo -e "\033[33mPULL REQUEST CREATION:\033[0m"
    echo "  gpr <title> [body] [base]"
    echo "                  - Create pull request"
    echo "                    Example: gpr 'Add login' 'New feature' main"
    
    echo ""
    echo -e "\033[33mPULL REQUEST VIEWING:\033[0m"
    echo "  prs             - List all open pull requests"
    echo "  prv <number>    - View specific PR details"
    echo "                    Example: prv 123"
    echo "  prl             - List PRs (alias for prs)"
    echo "  prc <number>    - Check PR status/checks"
    echo "  prd <number>    - View PR diff"
    echo "  prco <number>   - Checkout PR branch locally"
    
    echo ""
    echo -e "\033[33mPULL REQUEST REVIEW:\033[0m"
    echo "  prapprove <number> [comment]"
    echo "                  - Approve a pull request"
    echo "                    Example: prapprove 123 'Great work!'"
    echo "  prchanges <number> <comment>"
    echo "                  - Request changes on PR (comment required)"
    echo "                    Example: prchanges 123 'Please add tests'"
    
    echo ""
    echo -e "\033[33mPULL REQUEST MERGING:\033[0m"
    echo "  gmerge [type]   - Merge current branch's PR"
    echo "                    Types: merge (default), squash, rebase"
    echo "                    Example: gmerge squash"
    
    echo ""
    echo -e "\033[33mHELP:\033[0m"
    echo "  ghelp           - Show this help message"
    
    echo ""
    echo "=== Usage Examples ==="
    echo -e "\033[32m# Complete workflow:\033[0m"
    echo "gb                          # List branches"
    echo "gnewb feature-auth          # Create new branch"
    echo "# ... make changes ..."
    echo "ga ."
    echo "gc 'Add authentication'"
    echo "gps                         # Push changes"
    echo "gpr 'Add user auth' 'New login system'"
    echo "# ... wait for review ..."
    echo "gmerge                      # Merge when approved"
    echo "gco main                    # Switch back to main"
    echo "gdel feature-auth           # Delete merged branch"
    echo ""
}

echo "🎉 Git & GitHub functions loaded successfully!"
echo "Type 'ghelp' to see all available commands and examples"
