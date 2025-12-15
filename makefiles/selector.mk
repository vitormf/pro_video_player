# Interactive task selector using fzf with category navigation
# Displays all available Make commands organized by category

.PHONY: select

# Interactive menu to select and run Make tasks with fzf
# Shows categories first, ESC goes back to categories instead of exiting
# Depends on _check-fzf from verify.mk for installation check
select: _check-fzf
	@$(SCRIPTS_DIR)/task-selector.sh "$(FLUTTER)" "$(IOS_SIMULATOR_ID)"
