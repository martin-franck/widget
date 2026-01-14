# Recast.tv Widget Testing Repository

This repository contains test pages for embedding Recast.tv widgets across different environments.

## Structure

All HTML files are organized by environment and accessed through `index.html`:

### Environments

- **Ephemeral/Other** - Temporary testing environments for feature development
- **TST** - Testing environment
- **STG** - Staging environment
- **Production** - Live production widgets

## Widget Types

- **Channel widgets** - Embed channel streams and content
- **Video widgets** - Embed individual videos or multiple videos
- **Affiliate widgets** - Channel and video widgets for affiliate partners

## Usage

1. Open `index.html` in a browser to see all available test pages
2. Click any link to view the corresponding widget embedding test
3. Each HTML file contains an iframe embedding a Recast.tv widget

## File Naming Convention

Files follow the pattern: `{environment}-{widget-type}.html`

Examples:
- `tst-channel-widget.html` - Channel widget in testing environment
- `stg-channel-widget.html` - Channel widget in staging environment
- `prod-petes-widget.html` - Production widget for Pete's channel
- `ephem-tst-channel-widget.html` - Ephemeral/experimental test widget

## Adding New Widgets

To add a new widget test page:

1. Create an HTML file following the naming convention
2. Copy the basic structure from an existing file
3. Update the widget iframe `id` and `src` attributes
4. Update the script `iframe-id` attribute to match
5. Add a link to the new file in `index.html` under the appropriate environment column
