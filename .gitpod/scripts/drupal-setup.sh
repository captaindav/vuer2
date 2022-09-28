#!/usr/bin/env bash
if [ -n "$DEBUG_DRUXTJS" ]; then
    set -x
fi

# Set up ddev for use on gitpod

set -eu -o pipefail

DRUPAL_DIR="${GITPOD_REPO_ROOT}/docs/drupal"

# Set up Drupal website
cd "$DRUPAL_DIR" && ddev start -y
# cd "$DRUPAL_DIR" && ddev drupal-install
cd "$DRUPAL_DIR" && ddev drush -y site-install standard --account-pass admin --site-name "Drupal Outline" --db-url mysql://drupal9:drupal9@database/drupal9
cd "$DRUPAL_DIR" && ddev drush -y en content_moderation, media, media_library, workflows
cd "$DRUPAL_DIR" && ddev drush -y en admin_toolbar, admin_toolbar_tools, admin_toolbar_links_access_filter, admin_toolbar_search
cd "$DRUPAL_DIR" && ddev drush -y en ctools, devel, druxt, graphql, paragraphs, pathauto, token
cd "$DRUPAL_DIR" && ddev drush -y en outline, outline_graphql
cd "$DRUPAL_DIR" && ddev drush cr